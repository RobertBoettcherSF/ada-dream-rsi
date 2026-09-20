package body Dream_RSI is

   procedure Initialize_Root
     (Tree          : out Discovery_Tree;
      Initial_Score : Score_Value)
   is
   begin
      Tree.Count := 1;
      Tree.Nodes (1) := (Parent => Null_Index,
                         State  => Evaluated,
                         Score  => Initial_Score,
                         Cost   => 0.0);
   end Initialize_Root;

   procedure Add_Node
     (Tree   : in out Discovery_Tree;
      Parent : Valid_Node_Index;
      State  : Node_State;
      Score  : Score_Value;
      Cost   : Compute_Cost;
      ID     : out Valid_Node_Index)
   is
   begin
      if Tree.Count = Max_Tree_Nodes then
         raise Tree_Full_Error;
      end if;
      if Parent > Node_Index (Tree.Count) then
         raise Invalid_Parent_Error;
      end if;

      Tree.Count := Tree.Count + 1;
      ID := Valid_Node_Index (Tree.Count);
      Tree.Nodes (ID) := (Parent => Parent,
                          State  => State,
                          Score  => Score,
                          Cost   => Cost);
   end Add_Node;

   function Is_Valid_Tree (Tree : Discovery_Tree) return Boolean is
   begin
      if Tree.Count = 0 then
         return True; -- Empty tree is trivially valid
      end if;
      if Tree.Nodes (1).Parent /= Null_Index then
         return False; -- Root must have no parent
      end if;
      for I in 2 .. Tree.Count loop
         -- Parents must exist and physically precede the child to strictly avoid cycles
         if Tree.Nodes (Valid_Node_Index (I)).Parent = Null_Index or else
            Tree.Nodes (Valid_Node_Index (I)).Parent >= Node_Index (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Tree;

   function Construct_Replay_Simulator (History : Discovery_Tree) return Discovery_Tree is
      Simulator : Discovery_Tree := (Count => 0, Nodes => [others => (Parent => Null_Index, State => Unexplored, Score => 0.0, Cost => 0.0)]);
   begin
      if History.Count = 0 then
         raise Tree_Empty_Error;
      end if;

      for I in 1 .. History.Count loop
         -- Dream-RSI requires only evaluated states to act as the off-policy simulator
         if History.Nodes (Valid_Node_Index (I)).State = Evaluated then
            Simulator.Count := Simulator.Count + 1;
            Simulator.Nodes (Valid_Node_Index (Simulator.Count)) := History.Nodes (Valid_Node_Index (I));
         end if;
      end loop;

      -- A tree could have >0 nodes, but all Unexplored. If so, Simulator is essentially empty.
      return Simulator;
   end Construct_Replay_Simulator;

   function Evaluate_Policy
     (Simulator : Discovery_Tree;
      Policy    : Exploration_Policy) return Score_Value
   is
      Total_Score     : Score_Value := 0.0;
      Nodes_Evaluated : Natural := 0;
   begin
      if Simulator.Count = 0 then
         return 0.0;
      end if;

      for I in 1 .. Simulator.Count loop
         declare
            Node    : constant Discovery_Node := Simulator.Nodes (Valid_Node_Index (I));
            Base    : constant Float := Float (Node.Score);

            -- Theoretical optimal exploration weight is 0.5.
            -- This simulates outcome evaluation: policies drifting from the optimum incur penalties.
            Penalty : constant Float := abs (Policy.Exploration_Weight - 0.5) * 10.0;
         begin
            Total_Score := Total_Score + Score_Value (Base - Penalty);
            Nodes_Evaluated := Nodes_Evaluated + 1;
         end;
      end loop;

      if Nodes_Evaluated = 0 then
         return 0.0;
      end if;
      return Total_Score / Score_Value (Nodes_Evaluated);
   end Evaluate_Policy;

   function Improve_Policy (Simulator : Discovery_Tree) return Exploration_Policy is
      Best_Policy : Exploration_Policy := (Exploration_Weight => 0.0);
      Best_Score  : Score_Value := Score_Value'First;
      Curr_Policy : Exploration_Policy;
      Curr_Score  : Score_Value;
   begin
      if Simulator.Count = 0 then
         raise Tree_Empty_Error;
      end if;

      -- Grid search to model the recursive self-improvement offline optimization
      for I in 0 .. 10 loop
         Curr_Policy.Exploration_Weight := Float (I) / 10.0;
         Curr_Score := Evaluate_Policy (Simulator, Curr_Policy);
         if Curr_Score > Best_Score then
            Best_Score := Curr_Score;
            Best_Policy := Curr_Policy;
         end if;
      end loop;
      return Best_Policy;
   end Improve_Policy;

   function Recursive_Fixed_Exploration
     (Tree   : Discovery_Tree;
      Budget : Natural) return Score_Value
   is
      Fixed_Policy : constant Exploration_Policy := (Exploration_Weight => 1.0); -- Baseline non-adaptive
      Simulator    : constant Discovery_Tree := Construct_Replay_Simulator (Tree);
   begin
      if Simulator.Count = 0 then
         return 0.0;
      end if;
      return Evaluate_Policy (Simulator, Fixed_Policy) * Score_Value (Budget);
   end Recursive_Fixed_Exploration;

   function Dream_RSI_Exploration
     (Tree   : Discovery_Tree;
      Budget : Natural) return Score_Value
   is
      Simulator   : constant Discovery_Tree := Construct_Replay_Simulator (Tree);
      Best_Policy : Exploration_Policy;
   begin
      if Simulator.Count = 0 then
         return 0.0;
      end if;

      -- Core RSI loop: Dream inside the simulator to improve exploration policy dynamically
      Best_Policy := Improve_Policy (Simulator);

      -- Redeploy improved online policy (budget scaling simulates parallel rollout capability)
      return Evaluate_Policy (Simulator, Best_Policy) * Score_Value (Budget);
   end Dream_RSI_Exploration;

end Dream_RSI;
