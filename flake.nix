{
    inputs =
        {
        } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        coreutils ,
                        error-planned ,
                        error-unplanned ,
                        jq ,
                        visitor ,
                        writeShellApplication
                    } :
                        let
                            implementation =
                                compile-time-arguments :
                                    let
                                        implementation-parameters =
                                            {
                                                compile-time-arguments =
                                                    visitor
                                                        {
                                                            bool = path : value : value ;
                                                            float = path : value : value ;
                                                            int = path : value : value ;
                                                            lambda = path : value : null ;
                                                            null = path : value : value ;
                                                            path = path : value : value ;
                                                            string = path : value : value ;
                                                        }
                                                        compile-time-arguments ;
                                            } ;
                                        in
                                            root-parameters.writeShellApplication
                                                {
                                                    name = "failure" ;
                                                    runtimeInputs = [ root-parameters.coreutils root-parameters.jq ] ;
                                                    text =
                                                        ''
                                                            COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON implementation-parameters.compile-time-arguments ) } )" || exit ${ root-parameters.error-unplanned }
                                                            if [[ -t 0 ]]
                                                            then
                                                                jq \
                                                                    --null-input \
                                                                    --argjson COMPILE_TIME_ARGUMENTS "$COMPILE_TIME_ARGUMENTS" \
                                                                    --args \
                                                                    '{
                                                                        "arguments" :
                                                                            {
                                                                                "compile" : $COMPILE_TIME_ARGUMENTS ,
                                                                                "run" : $ARGS.positional
                                                                            } ,
                                                                        "inputs" : { }
                                                                    }' -- "$@" >&2
                                                            else
                                                                STANDARD_INPUT="$( cat )" || exit ${ builtins.toString root-parameters.error-unplanned }
                                                                jq \
                                                                    --null-input \
                                                                    --argjson COMPILE_TIME_ARGUMENTS "$COMPILE_TIME_ARGUMENTS" \
                                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                    --args \
                                                                    '{
                                                                        "arguments" :
                                                                            {
                                                                                "compile" : $COMPILE_TIME_ARGUMENTS ,
                                                                                "run" : $ARGS.positional
                                                                            } ,
                                                                        "inputs" :
                                                                            {
                                                                                "standard" : $STANDARD_INPUT
                                                                            }
                                                                    }' -- "$@" >&2
                                                            fi
                                                            exit ${ builtins.toString root-parameters.error-planned }
                                                        '' ;
                                                } ;
                                    root-parameters =
                                        {
                                            coreutils = coreutils ;
                                            error-planned = visitor { int = path : value : builtins.toString value ; } error-planned ;
                                            error-unplanned = visitor { int = path : value : builtins.toString value ; } error-unplanned ;
                                            jq = jq ;
                                            writeShellApplication = writeShellApplication ;
                                            visitor = visitor ;
                                        } ;
                            in
                                {
                                    check =
                                        {
                                            compile-time-arguments ? null ,
                                            diffutils ,
                                            mkDerivation ,
                                            order ,
                                            run-time-arguments ? [ ] ,
                                            standard-input ? null
                                        } :
                                            let
                                                check-parameters =
                                                    {
                                                        compile-time-arguments = compile-time-arguments ;
                                                        diffutils = diffutils ;
                                                        mkDerivation = mkDerivation ;
                                                        order = order ;
                                                        run-time-arguments = run-time-arguments ;
                                                        standard-input = root-parameters.visitor { null = path : value : value ; string = path : value : builtins.toFile "standard-input" value ; } standard-input ;
                                                    } ;
                                                value =
                                                    check-parameters.mkDerivation
                                                        {
                                                            installPhase = ''install $out'' ;
                                                            name = "check" ;
                                                            nativeBuildInputs =
                                                                [
                                                                    (
                                                                        writeShellApplication
                                                                            {
                                                                                name = "install" ;
                                                                                runtimeInputs = [ root-parameters.coreutils root-parameters.jq ( implementation check-parameters.compile-time-arguments ) ] ;
                                                                                text =
                                                                                    if builtins.typeOf check-parameters.standard-input == "null" then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON check-parameters.compile-time-arguments ) } )" || exit ${ root-parameters.error-unplanned }
                                                                                            RUN_TIME_ARGUMENTS="$( cat ${ builtins.toFile "run-time-arguments.json" ( builtins.toJSON check-parameters.run-time-arguments ) } )" || exit ${ root-parameters.error-unplanned }
                                                                                            mkdir --parents "$OUT/expected"
                                                                                            jq \
                                                                                                --null-input \
                                                                                                --sort-keys \
                                                                                                --argjson COMPILE_TIME_ARGUMENTS "$COMPILE_TIME_ARGUMENTS" \
                                                                                                --argjson RUN_TIME_ARGUMENTS "$RUN_TIME_ARGUMENTS" \
                                                                                                '{
                                                                                                    "arguments" :
                                                                                                        {
                                                                                                            "compile" : $COMPILE_TIME_ARGUMENTS ,
                                                                                                            "run" : $RUN_TIME_ARGUMENTS
                                                                                                        } ,
                                                                                                    "inputs" : { }
                                                                                                }' > "$OUT/expected/standard-error"
                                                                                            echo -n "" > "$OUT/expected/standard-output"
                                                                                            echo -n ${ root-parameters.error-planned } > "$OUT/expected/status"
                                                                                            mkdir --parents "$OUT/observed"
                                                                                            if failure ${ builtins.concatStringsSep " " check-parameters.run-time-arguments } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
                                                                                            then
                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                            else
                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                            fi
                                                                                            diff --unified "$OUT/expected" "$OUT/observed"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            mkdir --parents "$OUT/expected"
                                                                                            COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON check-parameters.compile-time-arguments ) } )" || exit ${ root-parameters.error-unplanned }
                                                                                            RUN_TIME_ARGUMENTS="$( cat ${ builtins.toFile "run-time-arguments.json" ( builtins.toJSON check-parameters.run-time-arguments ) } )" || exit ${ root-parameters.error-unplanned }
                                                                                            jq \
                                                                                                --null-input \
                                                                                                --sort-keys \
                                                                                                --argjson COMPILE_TIME_ARGUMENTS "$COMPILE_TIME_ARGUMENTS" \
                                                                                                --argjson RUN_TIME_ARGUMENTS "$RUN_TIME_ARGUMENTS" \
                                                                                                --rawfile STANDARD_INPUT ${ check-parameters.standard-input } \
                                                                                                '{
                                                                                                    "arguments" :
                                                                                                        {
                                                                                                            "compile" : $COMPILE_TIME_ARGUMENTS ,
                                                                                                            "run" : $RUN_TIME_ARGUMENTS
                                                                                                        } ,
                                                                                                    "inputs" :
                                                                                                        {
                                                                                                            "standard" : $STANDARD_INPUT
                                                                                                        }
                                                                                                }' > "$OUT/expected/standard-error"
                                                                                            echo -n "" > "$OUT/expected/standard-output"
                                                                                            echo -n ${ root-parameters.error-planned } > "$OUT/expected/status"
                                                                                            mkdir --parents "$OUT/observed"
                                                                                            if failure ${ builtins.concatStringsSep " " check-parameters.run-time-arguments } < ${ check-parameters.standard-input } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
                                                                                            then
                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                            else
                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                            fi
                                                                                            echo "$0" "$OUT" >&2
                                                                                            diff --unified "$OUT/expected" "$OUT/observed"
                                                                                        '' ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            src = ./. ;
                                                        } ;
                                                in
                                                    {
                                                        name = builtins.concatStringsSep "-" [ "check" ( builtins.toString check-parameters.order ) ] ;
                                                        order = check-parameters.order ;
                                                        value = dependencies : value ;
                                                    } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
