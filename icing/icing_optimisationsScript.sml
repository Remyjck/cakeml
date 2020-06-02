(*
  Icing optimisations supported by CakeML
*)
open bossLib;
open fpValTreeTheory fpOptTheory;

open preamble;

val _ = new_theory "icing_optimisations";

(*
  Commutativity
*)
Definition fp_comm_gen_def:
  fp_comm_gen op = (Binop op (Var 0) (Var 1), Binop op (Var 1) (Var 0))
End

val fp_add_comm_def =
  curry save_thm "fp_add_comm_def" (Q.SPEC `FP_Add` fp_comm_gen_def);

val fp_mul_comm_def =
  curry save_thm "fp_mul_comm_def" (Q.SPEC `FP_Mul` fp_comm_gen_def);

(*
  Associativity
*)
Definition fp_assoc_gen_def:
  fp_assoc_gen op = (Binop op (Binop op (Var 0) (Var 1)) (Var 2),
                     Binop op (Var 0) (Binop op (Var 1) (Var 2)))
End

val fp_add_assoc_def =
  curry save_thm "fp_add_assoc_def"
    (Q.SPEC `FP_Add` fp_assoc_gen_def);

val fp_mul_assoc_def =
  curry save_thm "fp_mul_assoc_def"
    (Q.SPEC `FP_Mul` fp_assoc_gen_def);

(*
  Double negation
*)
Definition fp_double_neg_def:
  fp_double_neg = (Unop FP_Neg (Unop FP_Neg (Var 0)), Var 0)
End

(*
  Distributivity of multiplication over addition
*)
Definition fp_mul_distrib_def:
  fp_mul_distrib = (Binop FP_Mul (Var 0) (Binop FP_Add (Var 1) (Var 2)),
                    Binop FP_Add (Binop FP_Mul (Var 0) (Var 1))
                                 (Binop FP_Mul (Var 0) (Var 2)))
End

(*
  FMA introudction
*)
Definition fp_fma_intro_def:
  fp_fma_intro = (Binop FP_Add (Binop FP_Mul (Var 0) (Var 1)) (Var 2),
                  Terop FP_Fma (Var 0) (Var 1) (Var 2))
End

val _ = export_theory ();
