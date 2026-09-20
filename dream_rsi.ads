package Dream_RSI is

   type Node_Index is new Natural;
   Null_Index : constant Node_Index := 0;

   type Node_State is (Unexplored, Evaluated, Failed);
   type Score_Value is new Float;
   type Compute_Cost is new Float range 0.0 .. Float'Last;

   type Discovery_Node is record
      Parent : Node_Index := Null_Index;
      State  : Node_State := Unexplored;
      Score  : Score_Value := 0.0;
      Cost   : Compute_Cost := 0.0;
   end record;

   Max_Tree_Nodes : constant := 1000;
   subtype Valid_Node_Count is Natural range 0 .. Max_Tree_Nodes;
   subtype Valid_Node_Index is Node_Index range 1 .. Node_Index (Max_Tree_Nodes);

   type Node_Array is array (Valid_Node_Index) of Discovery_Node;

   type Discovery_Tree is record
      Nodes : Node_Array := (others => (Parent => Null_Index, State => Unexplored, Score => 0.0, Cost => 0.0));
      Count : Valid_Node_Count := 0;
   end record;

   type Exploration_Policy is record
      Exploration_Weight : Float range 0.0 .. 1.0 := 1.0;
   end record;

   -- Exceptions
   Tree_Empty_Error     : exception;
   Tree_Full_Error      : exception;
   Invalid_Parent_Error : exception;

   -- Core Tree Management
   procedure Initialize_Root
     (Tree          : out Discovery_Tree;
      Initial_Score : Score_Value)
     with Global => null,
          Post   => Tree.Count = 1;

   procedure Add_Node
     (Tree   : in out Discovery_Tree;
      Parent : Valid_Node_Index;
      State  : Node_State;
      Score  : Score_Value;
      Cost   : Compute_Cost;
      ID     : out Valid_Node_Index)
     with Global => null,
          Pre    => Tree.Count >= 1,
          Post   => Tree.Count = Tree'Old.Count + 1;

   function Is_Valid_Tree (Tree : Discovery_Tree) return Boolean
     with Global => null;

   -- Helper: Extract only evaluated nodes into a "Replay Simulator"
   function Construct_Replay_Simulator (History : Discovery_Tree) return Discovery_Tree
     with Global => null;

   -- Helper: Evaluate a given exploration policy against the simulator
   function Evaluate_Policy
     (Simulator : Discovery_Tree;
      Policy    : Exploration_Policy) return Score_Value
     with Global => null;

   -- Helper: Optimize policy weights using the simulator (Dreaming)
   function Improve_Policy (Simulator : Discovery_Tree) return Exploration_Policy
     with Global => null;

   -- Variant 1: Baseline Recursive Fixed Exploration (Static Strategy)
   function Recursive_Fixed_Exploration
     (Tree   : Discovery_Tree;
      Budget : Natural) return Score_Value
     with Global => null;

   -- Variant 2: Dream-RSI Exploration (Dynamic Self-Improving Strategy)
   function Dream_RSI_Exploration
     (Tree   : Discovery_Tree;
      Budget : Natural) return Score_Value
     with Global => null;

end Dream_RSI;
