#use "hol.ml";;
#use "Examples/sos.ml";;
time PURE_SOS `! x. (&858993459/8589934592):real <= x /\ x <= (&1):real ==> ( ( (&5517561/4294967296) ) + ( ( x * (&-139975391/8589934592) ) + ( ( x pow 2 * (&260655175/4294967296) ) + ( ( x pow 3 * (&-2948059219/34359738368) ) + ( ( x pow 4 * (&1/24) ) + ( ( x pow 6 * (&-1/720) ) + ( ( x pow 8 * (&1/40320) ) + ( ( x pow 10 * (&-1/3628800) ) + ( ( x pow 12 * (&1/479001600) ) + ( x pow 14 * (&-1/87178291200) ) ) ) ) ) ) ) ) )):real <= (&371624070877589/1371195958099968000):real`;;