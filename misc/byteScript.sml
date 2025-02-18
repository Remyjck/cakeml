(*
  A theory about byte-level manipulation of machine words.
*)

open HolKernel boolLib bossLib dep_rewrite Parse
     arithmeticTheory rich_listTheory wordsTheory

val _ = new_theory "byte";

val _ = set_grammar_ancestry ["arithmetic", "list", "words"];
val _ = temp_tight_equality();

(* Get and set bytes in a word *)

Definition byte_index_def:
  byte_index (a:'a word) is_bigendian =
    let d = dimindex (:'a) DIV 8 in
      if is_bigendian then 8 * ((d - 1) - w2n a MOD d) else 8 * (w2n a MOD d)
End

Definition get_byte_def:
  get_byte (a:'a word) (w:'a word) is_bigendian =
    (w2w (w >>> byte_index a is_bigendian)):word8
End

Definition word_slice_alt_def:
  (word_slice_alt h l (w:'a word) :'a word) = FCP i. l <= i /\ i < h /\ w ' i
End

Definition set_byte_def[nocompute]:
  set_byte (a:'a word) (b:word8) (w:'a word) is_bigendian =
    let i = byte_index a is_bigendian in
      (word_slice_alt (dimindex (:'a)) (i + 8) w
       || w2w b << i
       || word_slice_alt i 0 w)
End

Theorem set_byte_32[compute]:
  set_byte a b (w:word32) be =
    let i = byte_index a be in
      if i = 0  then w2w b       || (w && 0xFFFFFF00w) else
      if i = 8  then w2w b << 8  || (w && 0xFFFF00FFw) else
      if i = 16 then w2w b << 16 || (w && 0xFF00FFFFw) else
                     w2w b << 24 || (w && 0x00FFFFFFw)
Proof
  fs [set_byte_def]
  \\ qsuff_tac ‘byte_index a be = 0 ∨
                byte_index a be = 8 ∨
                byte_index a be = 16 ∨
                byte_index a be = 24’
  THEN1 (rw [] \\ fs [word_slice_alt_def] \\ blastLib.BBLAST_TAC)
  \\ fs [byte_index_def]
  \\ ‘w2n a MOD 4 < 4’ by fs [MOD_LESS] \\ rw []
QED

Theorem set_byte_64[compute]:
  set_byte a b (w:word64) be =
    let i = byte_index a be in
      if i = 0  then w2w b       || (w && 0xFFFFFFFFFFFFFF00w) else
      if i = 8  then w2w b << 8  || (w && 0xFFFFFFFFFFFF00FFw) else
      if i = 16 then w2w b << 16 || (w && 0xFFFFFFFFFF00FFFFw) else
      if i = 24 then w2w b << 24 || (w && 0xFFFFFFFF00FFFFFFw) else
      if i = 32 then w2w b << 32 || (w && 0xFFFFFF00FFFFFFFFw) else
      if i = 40 then w2w b << 40 || (w && 0xFFFF00FFFFFFFFFFw) else
      if i = 48 then w2w b << 48 || (w && 0xFF00FFFFFFFFFFFFw) else
                     w2w b << 56 || (w && 0x00FFFFFFFFFFFFFFw)
Proof
  fs [set_byte_def]
  \\ qsuff_tac ‘byte_index a be = 0 ∨
                byte_index a be = 8 ∨
                byte_index a be = 16 ∨
                byte_index a be = 24 ∨
                byte_index a be = 32 ∨
                byte_index a be = 40 ∨
                byte_index a be = 48 ∨
                byte_index a be = 56’
  THEN1 (rw [] \\ fs [word_slice_alt_def] \\ blastLib.BBLAST_TAC)
  \\ fs [byte_index_def]
  \\ ‘w2n a MOD 8 < 8’ by fs [MOD_LESS] \\ rw []
QED

Theorem set_byte_change_a:
  w2n (a:α word) MOD (dimindex(:α) DIV 8) = w2n a' MOD (dimindex(:α) DIV 8) ⇒
    set_byte a b w be = set_byte a' b w be
Proof
  rw[set_byte_def,byte_index_def]
QED

Theorem get_byte_set_byte:
  8 ≤ dimindex(:α) ⇒
  (get_byte a (set_byte (a:'a word) b w be) be = b)
Proof
  fs [get_byte_def,set_byte_def]
  \\ fs [fcpTheory.CART_EQ,w2w] \\ rpt strip_tac
  \\ `i < dimindex (:'a)` by fs[dimindex_8]
  \\ fs [word_or_def,fcpTheory.FCP_BETA,word_lsr_def,word_lsl_def]
  \\ `i + byte_index a be < dimindex (:'a)` by (
    fs [byte_index_def,LET_DEF]
    \\ qmatch_goalsub_abbrev_tac`_ MOD dd`
    \\ match_mp_tac LESS_EQ_LESS_TRANS
    \\ qexists_tac`i + 8 * (dd-1)`
    \\ `0 < dd` by fs[Abbr`dd`, X_LT_DIV, NOT_LESS, dimindex_8]
    \\ conj_tac
    >- (
      rw[]
      \\ `w2n a MOD dd < dd` by (match_mp_tac MOD_LESS \\ decide_tac)
      \\ simp[] )
    \\ match_mp_tac LESS_LESS_EQ_TRANS
    \\ qexists_tac`8 * dd`
    \\ simp[LEFT_SUB_DISTRIB]
    \\ fs[dimindex_8]
    \\ qspec_then`8`mp_tac DIVISION
    \\ impl_tac >- simp[]
    \\ disch_then(qspec_then`dimindex(:α)`(SUBST1_TAC o CONJUNCT1))
    \\ simp[] )
  \\ fs [word_or_def,fcpTheory.FCP_BETA,word_lsr_def,word_lsl_def,
         word_slice_alt_def,w2w] \\ rfs []
  \\ `~(i + byte_index a be < byte_index a be)` by decide_tac
  \\ fs[dimindex_8]
QED

(* Convert between lists of bytes and words *)

Definition bytes_in_word_def:
  bytes_in_word = n2w (dimindex (:'a) DIV 8):'a word
End

Definition word_of_bytes_def:
  (word_of_bytes be a [] = 0w) /\
  (word_of_bytes be a (b::bs) =
     set_byte a b (word_of_bytes be (a+1w) bs) be)
End

Definition words_of_bytes_def:
  (words_of_bytes be [] = ([]:'a word list)) /\
  (words_of_bytes be bytes =
     let xs = TAKE (MAX 1 (w2n (bytes_in_word:'a word))) bytes in
     let ys = DROP (MAX 1 (w2n (bytes_in_word:'a word))) bytes in
       word_of_bytes be 0w xs :: words_of_bytes be ys)
Termination
  WF_REL_TAC `measure (LENGTH o SND)` \\ fs []
End

Theorem LENGTH_words_of_bytes:
   8 ≤ dimindex(:'a) ⇒
   ∀be ls.
   (LENGTH (words_of_bytes be ls : 'a word list) =
    LENGTH ls DIV (w2n (bytes_in_word : 'a word)) +
    MIN 1 (LENGTH ls MOD (w2n (bytes_in_word : 'a word))))
Proof
  strip_tac
  \\ recInduct words_of_bytes_ind
  \\ `1 ≤ w2n bytes_in_word`
  by (
    simp[bytes_in_word_def,dimword_def]
    \\ DEP_REWRITE_TAC[LESS_MOD]
    \\ rw[DIV_LT_X, X_LT_DIV, X_LE_DIV]
    \\ match_mp_tac LESS_TRANS
    \\ qexists_tac`2 ** dimindex(:'a)`
    \\ simp[X_LT_EXP_X] )
  \\ simp[words_of_bytes_def]
  \\ conj_tac
  >- ( DEP_REWRITE_TAC[ZERO_DIV] \\ fs[] )
  \\ rw[ADD1]
  \\ `MAX 1 (w2n (bytes_in_word:'a word)) = w2n (bytes_in_word:'a word)`
      by rw[MAX_DEF]
  \\ fs[]
  \\ qmatch_goalsub_abbrev_tac`(m - n) DIV _`
  \\ Cases_on`m < n` \\ fs[]
  >- (
    `m - n = 0` by fs[]
    \\ simp[]
    \\ simp[LESS_DIV_EQ_ZERO]
    \\ rw[MIN_DEF]
    \\ fs[Abbr`m`] )
  \\ simp[SUB_MOD]
  \\ qspec_then`1`(mp_tac o GEN_ALL)(Q.GEN`q`DIV_SUB) \\ fs[]
  \\ disch_then kall_tac
  \\ Cases_on`m MOD n = 0` \\ fs[]
  >- (
    DEP_REWRITE_TAC[SUB_ADD]
    \\ fs[X_LE_DIV] )
  \\ `MIN 1 (m MOD n) = 1` by simp[MIN_DEF]
  \\ fs[]
  \\ `m DIV n - 1 + 1 = m DIV n` suffices_by fs[]
  \\ DEP_REWRITE_TAC[SUB_ADD]
  \\ fs[X_LE_DIV]
QED

Theorem words_of_bytes_append:
   0 < w2n(bytes_in_word:'a word) ⇒
   ∀l1 l2.
   (LENGTH l1 MOD w2n (bytes_in_word:'a word) = 0) ⇒
   (words_of_bytes be (l1 ++ l2) : 'a word list =
    words_of_bytes be l1 ++ words_of_bytes be l2)
Proof
  strip_tac
  \\ gen_tac
  \\ completeInduct_on`LENGTH l1`
  \\ rw[]
  \\ Cases_on`l1` \\ fs[]
  >- EVAL_TAC
  \\ rw[words_of_bytes_def]
  \\ fs[PULL_FORALL]
  >- (
    simp[TAKE_APPEND]
    \\ qmatch_goalsub_abbrev_tac`_ ++ xx`
    \\ `xx = []` suffices_by rw[]
    \\ simp[Abbr`xx`]
    \\ fs[ADD1]
    \\ rfs[MOD_EQ_0_DIVISOR]
    \\ Cases_on`d` \\ fs[] )
  \\ simp[DROP_APPEND]
  \\ qmatch_goalsub_abbrev_tac`_ ++ DROP n l2`
  \\ `n = 0`
  by (
    simp[Abbr`n`]
    \\ rfs[MOD_EQ_0_DIVISOR]
    \\ Cases_on`d` \\ fs[ADD1] )
  \\ simp[]
  \\ first_x_assum irule
  \\ simp[]
  \\ rfs[MOD_EQ_0_DIVISOR, ADD1]
  \\ Cases_on`d` \\ fs[MULT]
  \\ simp[MAX_DEF]
  \\ IF_CASES_TAC \\ fs[NOT_LESS]
  >- metis_tac[]
  \\ Cases_on`w2n (bytes_in_word:'a word)` \\ fs[] \\ rw[]
  \\ Cases_on`n''` \\ fs[] \\ metis_tac []
QED

Theorem words_of_bytes_append_word:
  0 < LENGTH l1 ∧ (LENGTH l1 = w2n (bytes_in_word:'a word)) ⇒
  (words_of_bytes be (l1 ++ l2) = word_of_bytes be (0w:'a word) l1 :: words_of_bytes be l2)
Proof
  rw[]
  \\ Cases_on`l1` \\ rw[words_of_bytes_def] \\ fs[]
  \\ fs[MAX_DEF]
  \\ qabbrev_tac ‘k = w2n (bytes_in_word:'a word)’
  \\ fs[ADD1]
  \\ rw[TAKE_APPEND,DROP_APPEND,DROP_LENGTH_NIL] \\ fs[]
QED

Definition bytes_to_word_def:
  bytes_to_word k a bs w be =
    if k = 0:num then w else
      case bs of
      | [] => w
      | (b::bs) => set_byte a b (bytes_to_word (k-1) (a+1w) bs w be) be
End

Theorem bytes_to_word_eq:
  bytes_to_word 0 a bs w be = w ∧
  bytes_to_word k a [] w be = w ∧
  bytes_to_word (SUC k) a (b::bs) w be =
    set_byte a b (bytes_to_word k (a+1w) bs w be) be
Proof
  rw [] \\ simp [Once bytes_to_word_def]
QED

Theorem word_of_bytes_bytes_to_word:
  ∀be a bs k.
    LENGTH bs ≤ k ⇒
    (word_of_bytes be a bs = bytes_to_word k a bs 0w be)
Proof
  Induct_on`bs`
  >- (
    EVAL_TAC
    \\ Cases_on`k`
    \\ EVAL_TAC
    \\ rw[] )
  \\ rw[word_of_bytes_def]
  \\ Cases_on`k` \\ fs[]
  \\ rw[Once bytes_to_word_def]
  \\ AP_THM_TAC
  \\ AP_TERM_TAC
  \\ first_x_assum match_mp_tac
  \\ fs[]
QED

Theorem bytes_to_word_same:
  ∀bw k b1 w be b2.
    (∀n. n < bw ⇒ n < LENGTH b1 ∧ n < LENGTH b2 ∧ EL n b1 = EL n b2)
    ⇒
    (bytes_to_word bw k b1 w be = bytes_to_word bw k b2 w be)
Proof
  ho_match_mp_tac bytes_to_word_ind \\ rw []
  \\ once_rewrite_tac [bytes_to_word_def] \\ rw []
  \\ Cases_on`b1` \\ fs[]
  >- (first_x_assum(qspec_then`0`mp_tac) \\ simp[])
  \\ Cases_on`b2` \\ fs[]
  >- (first_x_assum(qspec_then`0`mp_tac) \\ simp[])
  \\ first_assum(qspec_then`0`mp_tac)
  \\ impl_tac >- simp[]
  \\ simp_tac(srw_ss())[] \\ rw[]
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ first_x_assum match_mp_tac
  \\ gen_tac \\ strip_tac
  \\ first_x_assum(qspec_then`SUC n`mp_tac)
  \\ simp[]
QED

val _ = export_theory();
