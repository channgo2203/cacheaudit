open Signatures
open AgeFunction

module AF = AgeFunction
(* An AgeFunctionSet is a set of partial cache states (AgeFunctions) *)
module type AGE_FUNCTION_SET = sig
  type t 

  (* Combines two AgeFunctionSets with distinct variables. *)
  val combine : t -> t -> t 
  (* True if there is a common variable v , s.t. there is no AF' in AFS with AF(v)=AF'(v) *)  
  val contradicts: t -> (var * int) list -> bool 
  (* Returns an empty set. *)
  val empty : t
  (* Tests if two AFS contain the same partial cache states. *)
  val equal : t -> t -> bool
  (* Filter the set according to a compare function applied two given variables. *)
  val filter_comp : t -> var -> var -> (int -> int -> int) -> t
  (* Filter all partial cache states from afs1 which constitue a contradiction to afs2. *)
  (* afs1 and afs2 can have different variable sets *)
  val filter : t -> t -> t
  (* Increase the age of a variable by 1 upto a given maximum age. *)
  val inc_var : t -> var -> int -> t
  (* Tests if the AgeFunctionSet is empty. *)
  val is_empty : t -> bool
  (* Joins two AgeFunctionSets with the same variables *)
  val join : t -> t -> t   
  (* Projects the AgeFunctionSet on the given list of variables. *)
  val project : t -> var list -> t
  (* Returns an AgeFunctionSet containing a single partial cache state in which the variable is assigned the given age. *)
  val singleton : var -> int -> t
  (* Tests if one AgeFunctionSet is a subset or equal to another AgeFunctionSet. *)
  val subseteq : t -> t -> bool
  (* Returns a string representation of the AgeFunctionSet *)
  val toString : t -> string
  (* Returns all possible ages of the given variable *)
  val values : t -> var -> int list
  (* Returns the set of variables of the AgeFunctionSet *)
  val vset : t -> VarSet.t
end

module AgeFunctionSet : AGE_FUNCTION_SET = struct
  module S = Set.Make(struct type t = AF.t let compare = AF.compare end)
  type t = {set : S.t; vars : VarSet.t}

  let is_empty afs : bool = S.is_empty afs.set

   let project afs vlist = 
    {set = S.fold (fun e set'-> S.add (AF.project e vlist) set') afs.set S.empty; 
     vars = VarSet.filter (fun v -> List.mem v vlist) afs.vars}

  let join afs1 afs2 = {afs1 with set = S.union afs1.set afs2.set}

   let combine afs1 afs2 = 
    if is_empty afs1 then afs2 else
    if is_empty afs2 then afs1 else
    let cross_join set1 set2 = S.fold (fun af1 set -> S.fold (fun af2 set' -> S.add (AF.join af1 af2) set') set2 set) set1 S.empty in
    let common_vars = VarSet.inter afs1.vars afs2.vars in
    if VarSet.is_empty common_vars then
      {set = cross_join afs1.set afs2.set; vars = VarSet.union afs1.vars afs2.vars}
    else
      let afs1_c = project afs1 (VarSet.elements common_vars) in
      let afs2_c = project afs2 (VarSet.elements common_vars) in
      let afs_c = {set = S.inter afs1_c.set afs2_c.set; vars = common_vars} in
      let afs1_d = project afs1 (VarSet.elements (VarSet.diff afs1.vars common_vars)) in
      let afs2_d = project afs2 (VarSet.elements (VarSet.diff afs2.vars common_vars)) in
      let afs_d = {set = cross_join afs1_d.set afs2_d.set; vars = VarSet.union afs1_d.vars afs2_d.vars} in
      {set = cross_join afs_c.set afs_d.set; vars = VarSet.union afs_c.vars afs_d.vars}

  let contradicts (afs:t) (part_state:(var * int) list) = 
    let af : AF.t = List.fold_left (fun af' (v,i) -> AF.add v i af') AF.empty part_state in
    let common_vars : VarSet.t = VarSet.inter afs.vars (AF.vars af) in
    not (S.exists (fun (af':AF.t) -> VarSet.for_all (fun (v:var) -> (AF.get v af) = (AF.get v af')) common_vars) afs.set)
    
  let empty = {set = S.empty; vars = VarSet.empty}

  let equal afs1 afs2 : bool = 
    if VarSet.equal afs1.vars afs2.vars then
      S.equal afs1.set afs2.set
    else false

  let filter afs1 afs2 : t = 
    let common_vars = VarSet.inter afs1.vars afs2.vars in
    let afs2_c = project afs2 (VarSet.elements common_vars) in
    {afs1 with set = S.filter (fun af -> let af = AF.project af (VarSet.elements common_vars) in
                                         S.exists (fun af' -> AF.compare af af' = 0) afs2_c.set) afs1.set}

  let filter_comp afs v1 v2 compare = 
    {afs with set = S.filter (fun af -> compare (AF.get v1 af) (AF.get v2 af) = -1) afs.set}

  let inc_var afs v max = 
    {afs with set = S.fold (fun af set -> S.add (AF.add v (Pervasives.min (AF.get v af + 1) max) af) set) afs.set S.empty}

  let singleton v i = {set = S.add (AF.add v i AF.empty) S.empty; vars = VarSet.add v VarSet.empty}

  let subseteq afs1 afs2 : bool = S.subset afs1.set afs2.set

  let toString afs : string =
    let s = S.fold (fun e s -> s ^ (AF.toString e) ^ ";") afs.set "" in
    if String.length s = 0 then "{ }" else "{" ^ (String.sub s 0 (String.length s -1)) ^ "}" 

  let values afs v = S.fold (fun af l -> let value = AF.get v af in if List.mem value l then l else value::l) afs.set []

  let vset afs = afs.vars

end

