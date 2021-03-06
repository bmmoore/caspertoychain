From mathcomp
Require Import all_ssreflect.
From fcsl
Require Import pred prelude ordtype pcm finmap unionmap heap.
From Casper
Require Import AccountableSafety ValidatorQuorum ValidatorDepositQuorum Blockforest ValidatorBlockforest.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(*
  This module instantiates the accountable safety theorem using
  the deposit-based validator quorums from
  ValidatorDepositQuorum.v
  and using the blocks from
  Blockforest.v,
  and considering only the votes recorded as block attestations.
 *)

Record NodeState :=
 Node {
   blocks : Blockforest;
 }.

Definition NodeInit : NodeState :=
  Node (#GenesisBlock \\-> GenesisBlock).

Inductive Input :=
| BlockT of block.

Definition procInp (st : NodeState) (inp : Input) :=
 let: Node bf := st in
 match inp with
 | BlockT b => Node (#b \\-> b \+ bf)
 end.

Definition Coh (ns : NodeState) :=
  [/\ valid (blocks ns),
     validH (blocks ns) &
     has_init_block (blocks ns)
  ].

Inductive system_step (ns ns' : NodeState) : Prop :=
| Idle of Coh ns /\ ns = ns'

| Intern (inp : Input) of
   Coh ns & ns' = procInp ns inp.

Definition vote_msg_bf (bf : Blockforest) (v : Validator) (h : Hash) (view : nat) (view_src: nat) : bool :=
  if find h bf is Some b then
    [&& block_view b == view & (@mkAR [ordType of Hash] view_src v) \in attestations b]
  else
    false.

Definition NodeState_State (ns : NodeState) : State Validator Hash :=
 mkSt (vote_msg_bf (blocks ns)).

Lemma accountable_safety_NodeState_deposit :
  forall (deposit : Validator -> nat) (ns : NodeState),
    finalization_fork (deposit_top deposit) (hash_parent_bf (blocks ns)) (# GenesisBlock) (NodeState_State ns) ->
    quorum_slashed (deposit_bot deposit) (NodeState_State ns).
Proof.
move => deposit ns.
exact: accountable_safety_bf_deposit.
Qed.
