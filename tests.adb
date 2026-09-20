--  SPDX-License-Identifier: MIT
--  Copyright (c) 2026 Robert Boettcher
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Dream_RSI;   use Dream_RSI;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   --  TEST 1 - Initialization
   Put_Line ("TEST 1 - Initialization");
   declare
      Tree : Discovery_Tree;
   begin
      Initialize_Root (Tree, 10.0);
      Check ("1.1 Tree count is 1", Tree.Count = 1);
      Check ("1.2 Root state is Evaluated", Tree.Nodes (1).State = Evaluated);
      Check ("1.3 Root score is correct", Tree.Nodes (1).Score = 10.0);
   end;

   --  TEST 2 - Add Node
   Put_Line ("TEST 2 - Add Node");
   declare
      Tree : Discovery_Tree;
      ID   : Valid_Node_Index;
   begin
      Initialize_Root (Tree, 10.0);
      Add_Node (Tree, 1, Unexplored, 0.0, 1.5, ID);
      Check ("2.1 Tree count is 2", Tree.Count = 2);
      Check ("2.2 New node ID is 2", ID = 2);
      Check ("2.3 New node parent is 1", Tree.Nodes (ID).Parent = 1);
   end;

   --  TEST 3 - Valid Tree Check
   Put_Line ("TEST 3 - Valid Tree Check");
   declare
      Tree : Discovery_Tree;
   begin
      Check ("3.1 Empty tree is valid", Is_Valid_Tree (Tree));
      Initialize_Root (Tree, 5.0);
      Check ("3.2 Root-only tree is valid", Is_Valid_Tree (Tree));
      Check ("3.3 Root parent is Null_Index", Tree.Nodes (1).Parent = Null_Index);
   end;

   --  TEST 4 - Invalid Tree Check (Cycle & Self-Loop)
   Put_Line ("TEST 4 - Invalid Tree Check (Cycle)");
   declare
      Tree : Discovery_Tree;
      ID   : Valid_Node_Index;
   begin
      Initialize_Root (Tree, 5.0);
      Add_Node (Tree, 1, Evaluated, 10.0, 1.0, ID);
      Check ("4.1 Initial valid state", Is_Valid_Tree (Tree));
      Tree.Nodes (1).Parent := 2;  -- backwards reference
      Check ("4.2 Cycle detected as invalid", not Is_Valid_Tree (Tree));
      Tree.Nodes (1).Parent := Null_Index;
      Tree.Nodes (2).Parent := 2;  -- self-loop
      Check ("4.3 Self-loop detected as invalid", not Is_Valid_Tree (Tree));
   end;

   --  TEST 5 - Tree Full Exception
   Put_Line ("TEST 5 - Tree Full Exception");
   declare
      Tree   : Discovery_Tree;
      ID     : Valid_Node_Index;
      Raised : Boolean := False;
   begin
      Initialize_Root (Tree, 0.0);
      for I in 2 .. Max_Tree_Nodes loop
         Add_Node (Tree, 1, Evaluated, 1.0, 1.0, ID);
      end loop;
      Check ("5.1 Tree is at maximum capacity", Tree.Count = Max_Tree_Nodes);
      begin
         Add_Node (Tree, 1, Evaluated, 1.0, 1.0, ID);
      exception
         when Tree_Full_Error =>
            Raised := True;
      end;
      Check ("5.2 Tree_Full_Error raised", Raised);
      Check ("5.3 Tree count remains unchanged", Tree.Count = Max_Tree_Nodes);
   end;

   --  TEST 6 - Invalid Parent Exception
   Put_Line ("TEST 6 - Invalid Parent Exception");
   declare
      Tree   : Discovery_Tree;
      ID     : Valid_Node_Index;
      Raised : Boolean := False;
   begin
      Initialize_Root (Tree, 0.0);
      Check ("6.1 Initial state count is 1", Tree.Count = 1);
      begin
         Add_Node (Tree, 999, Evaluated, 1.0, 1.0, ID);
      exception
         when Invalid_Parent_Error =>
            Raised := True;
      end;
      Check ("6.2 Invalid_Parent_Error raised", Raised);
      Check ("6.3 Tree count remains unchanged", Tree.Count = 1);
   end;

   --  TEST 7 - Replay Simulator Filter
   Put_Line ("TEST 7 - Replay Simulator Filter");
   declare
      Tree : Discovery_Tree;
      Sim  : Discovery_Tree;
      ID   : Valid_Node_Index;
   begin
      Initialize_Root (Tree, 10.0);
      Add_Node (Tree, 1, Unexplored, 0.0, 0.0, ID);
      Add_Node (Tree, 1, Failed, 0.0, 1.0, ID);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      Sim := Construct_Replay_Simulator (Tree);
      Check ("7.1 Simulator filtered to 2 nodes", Sim.Count = 2);
      Check ("7.2 Simulator node 1 is Evaluated", Sim.Nodes (1).State = Evaluated);
      Check ("7.3 Simulator node 2 is Evaluated", Sim.Nodes (2).State = Evaluated);
   end;

   --  TEST 8 - Replay Simulator Empty Exception
   Put_Line ("TEST 8 - Replay Simulator Empty Exception");
   declare
      Tree   : Discovery_Tree;
      Sim    : Discovery_Tree;
      Raised : Boolean := False;
   begin
      Check ("8.1 Tree is initially empty", Tree.Count = 0);
      begin
         Sim := Construct_Replay_Simulator (Tree);
      exception
         when Tree_Empty_Error =>
            Raised := True;
      end;
      Check ("8.2 Tree_Empty_Error raised", Raised);
      Check ("8.3 Simulator remains unpopulated", Sim.Count = 0);
   end;

   --  TEST 9 - Evaluate Policy Weights
   Put_Line ("TEST 9 - Evaluate Policy Weights");
   declare
      Tree     : Discovery_Tree;
      ID       : Valid_Node_Index;
      Pol1     : constant Exploration_Policy := (Exploration_Weight => 0.0);
      Pol2     : constant Exploration_Policy := (Exploration_Weight => 0.5);
      S1, S2   : Score_Value;
   begin
      Initialize_Root (Tree, 20.0);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      S1 := Evaluate_Policy (Tree, Pol1);
      S2 := Evaluate_Policy (Tree, Pol2);
      Check ("9.1 Optimal policy (0.5) scores higher than 0.0", S2 > S1);
      Check ("9.2 Baseline score is positive", S1 > 0.0);
      Check ("9.3 Optimal score is correct (20.0)", S2 = 20.0);
   end;

   --  TEST 10 - Evaluate Policy Extremes
   Put_Line ("TEST 10 - Evaluate Policy Extremes");
   declare
      Tree    : Discovery_Tree;
      ID      : Valid_Node_Index;
      Pol_Bad : constant Exploration_Policy := (Exploration_Weight => 1.0);
      S_Bad   : Score_Value;
   begin
      Initialize_Root (Tree, 20.0);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      S_Bad := Evaluate_Policy (Tree, Pol_Bad);
      Check ("10.1 Suboptimal policy receives penalty", S_Bad < 20.0);
      Check ("10.2 Suboptimal policy computes fine", S_Bad > 0.0);
      Check
        ("10.3 Penalty is symmetrical to 0.0 weight",
         S_Bad = Evaluate_Policy (Tree, (Exploration_Weight => 0.0)));
   end;

   --  TEST 11 - Improve Policy (Offline Dreaming)
   Put_Line ("TEST 11 - Improve Policy");
   declare
      Tree     : Discovery_Tree;
      ID       : Valid_Node_Index;
      Best_Pol : Exploration_Policy;
   begin
      Initialize_Root (Tree, 10.0);
      Add_Node (Tree, 1, Evaluated, 10.0, 1.0, ID);
      Best_Pol := Improve_Policy (Tree);
      Check
        ("11.1 Improved policy targets optimal 0.5 weight",
         Best_Pol.Exploration_Weight = 0.5);
      Check
        ("11.2 Improved policy is within valid range",
         Best_Pol.Exploration_Weight >= 0.0);
      Check
        ("11.3 Improved policy evaluates to max score",
         Evaluate_Policy (Tree, Best_Pol) = 10.0);
   end;

   --  TEST 12 - Recursive Fixed Exploration
   Put_Line ("TEST 12 - Recursive Fixed Exploration");
   declare
      Tree   : Discovery_Tree;
      ID     : Valid_Node_Index;
      Result : Score_Value;
   begin
      Initialize_Root (Tree, 20.0);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      Result := Recursive_Fixed_Exploration (Tree, 10);
      Check ("12.1 RFE result is positive", Result > 0.0);
      Check
        ("12.2 RFE matches fixed policy eval",
         Result
         = Evaluate_Policy (Tree, (Exploration_Weight => 1.0)) * 10.0);
      Check ("12.3 RFE scales exactly by budget", Result = 150.0);
   end;

   --  TEST 13 - Dream RSI Exploration
   Put_Line ("TEST 13 - Dream RSI Exploration");
   declare
      Tree        : Discovery_Tree;
      ID          : Valid_Node_Index;
      Base_Result : Score_Value;
      RSI_Result  : Score_Value;
   begin
      Initialize_Root (Tree, 20.0);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      Base_Result := Recursive_Fixed_Exploration (Tree, 10);
      RSI_Result  := Dream_RSI_Exploration (Tree, 10);
      Check
        ("13.1 RSI performs better than Fixed Exploration",
         RSI_Result > Base_Result);
      Check
        ("13.2 RSI logic matches optimal",
         RSI_Result
         = Evaluate_Policy (Tree, (Exploration_Weight => 0.5)) * 10.0);
      Check ("13.3 RSI optimal value is correct", RSI_Result = 200.0);
   end;

   --  TEST 14 - Edges: zero budget & empty Improve_Policy
   Put_Line ("TEST 14 - Edge Cases");
   declare
      Tree   : Discovery_Tree;
      ID     : Valid_Node_Index;
      Raised : Boolean := False;
      Empty  : Discovery_Tree;
   begin
      Initialize_Root (Tree, 20.0);
      Add_Node (Tree, 1, Evaluated, 20.0, 1.0, ID);
      Check
        ("14.1 Zero-budget RFE returns 0",
         Recursive_Fixed_Exploration (Tree, 0) = 0.0);
      Check
        ("14.2 Zero-budget RSI returns 0",
         Dream_RSI_Exploration (Tree, 0) = 0.0);
      begin
         declare
            Unused : constant Exploration_Policy := Improve_Policy (Empty);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Tree_Empty_Error =>
            Raised := True;
      end;
      Check ("14.3 Improve_Policy on empty tree raises Tree_Empty_Error", Raised);
   end;

   New_Line;
   Put_Line
     ("=== "
      & Natural'Image (Pass_Count)
      & " passed, "
      & Natural'Image (Fail_Count)
      & " failed ===");
   if Fail_Count > 0 then
      raise Program_Error with "tests failed";
   end if;
end Tests;
