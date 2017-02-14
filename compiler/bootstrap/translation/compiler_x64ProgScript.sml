open preamble
     x64ProgTheory
     configTheory
     ml_translatorLib
     ioProgLib

val () = new_theory "compiler_x64Prog";

val () = translation_extends "x64Prog";

(* TODO: move to inferencer (or update init_config?) *)
val prim_config_def = Define`
  prim_config = <|
    inf_decls := <|
        inf_defined_mods := [];
        inf_defined_types := [Short "option"; Short "list"; Short "bool"];
        inf_defined_exns := [Short "Subscript"; Short "Div"; Short "Chr"; Short "Bind"] |>;
    inf_env := init_env |>`;
(*
``env_rel prim_tenv prim_config.inf_env``
EVAL_TAC \\ rw[FEVERY_ALL_FLOOKUP]
\\ qexists_tac`[]` \\ EVAL_TAC

``prim_tdecs = convert_decls prim_config.inf_decls``
EVAL_TAC \\ rw[SUBSET_DEF]
*)

val res = translate inferTheory.init_env_def;

val res = translate prim_config_def;

val res = translate x64_names_def;

val res = translate compile_def;


val res = translate all_bytes_eq
val res = translate byte_to_string_eq

val byte_to_string_side_def = prove(
  ``!b. byte_to_string_side b``,
  fs [fetch "-" "byte_to_string_side_def"]
  \\ Cases \\ fs [] \\ EVAL_TAC \\ fs [])
  |> update_precondition;

val res = translate comma_cat_def;
val res = translate num_to_str_def;

val num_to_str_side_def = prove(
  ``!n. num_to_str_side n``,
  ho_match_mp_tac num_to_str_ind \\ rw []
  \\ once_rewrite_tac [fetch "-" "num_to_str_side_def"] \\ fs []
  \\ `n MOD 10 < 10` by fs [LESS_MOD] \\ decide_tac)
  |> update_precondition;

val res = translate bytes_row_def;
val res = translate listTheory.TAKE_def;
val res = translate listTheory.DROP_def;
val res = translate split16_def;
val res = translate ffi_asm_def;
val res = translate x64_export_def;

val error_to_str_def = Define`
  (error_to_str ParseError = "### ERROR: parse error") ∧
  (error_to_str TypeError = "### ERROR: type error") ∧
  (error_to_str CompileError = "### ERROR: compile error")`;

val res = translate error_to_str_def;

val compile_to_bytes_def = Define`
  compile_to_bytes c input =
    case compile c basis input of
    | Failure err => MAP (n2w o ORD) (error_to_str err)
    | Success (bytes,ffis) => x64_export ffis 400 100 bytes`;

val res = translate compile_to_bytes_def;

(* TODO: x64_compiler_config should be called x64_backend_config, and should
         probably be defined elsewhere *)
val compiler_x64_def = Define`
  compiler_x64 = compile_to_bytes <| inferencer_config := prim_config; backend_config := x64_compiler_config |>`;

val res = translate
  (x64_compiler_config_def
   |> SIMP_RULE(srw_ss())[FUNION_FUPDATE_1])

val res = translate compiler_x64_def;

val res = append_main_call "compiler_x64" ``compiler_x64``;

val () = Feedback.set_trace "TheoryPP.include_docs" 0;

val () = export_theory();
