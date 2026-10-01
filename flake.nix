{
    inputs =
        {
        } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
                        let
                            implementation =
                                { lib , pkgs , ... } :
                                    {
                                        options =
                                            {
                                                failure =
                                                    {
                                                        default =
                                                            {
                                                                compile-time-arguments ? null ,
                                                                shell-application ? pkgs.writeShellApplication ,
                                                                planned-error ? 176 ,
                                                                visitor ? builtins.toJSON ,
                                                                unplanned-error ? 118
                                                            } :
                                                                pkgs.writeShellApplication
                                                                    {
                                                                        name = "failure" ;
                                                                        runtimeInputs = [ pkgs.coreutils pkgs.jq ] ;
                                                                        text =
                                                                            ''
                                                                                COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON compile-time-arguments ) } )" || exit ${ builtins.toString unplanned-error }
                                                                                if [[ -t 0 ]]
                                                                                then
                                                                                    STANDARD_INPUT="$( cat )" || exit ${ builtins.toString unplanned-error }
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
                                                                                else
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
                                                                                fi
                                                                                exit ${ builtins.toString planned-error }
                                                                            '' ;
                                                                    } ;
                                                        type = lib.types.functionTo lib.types.package ;
                                                    } ;
                                            } ;
                                    } ;
                            in
                                {
                                    check =
                                        {
                                            nixosTest ,
                                            order
                                        } :
                                        {
                                            compile-time-arguments ,
                                            shell-application ,
                                            planned-error ,
                                            visitor ,
                                            unplanned-error
                                        } :
                                        {
                                            run-time-arguments ? [ ] ,
                                            standard-input ? null
                                        } :
                                            let
                                                value =
                                                    nixosTest
                                                        {
                                                            name = "failure" ;
                                                            nodes.client =
                                                                {
                                                                    client =
                                                                        { config , pkgs , ... }  :
                                                                            {
                                                                                environment.systemPackages =
                                                                                    [
                                                                                        (
                                                                                            pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "test-script" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            pkgs.coreutils
                                                                                                            pkgs.diffutils
                                                                                                            pkgs.jq
                                                                                                            (
                                                                                                                config.failure
                                                                                                                    {
                                                                                                                        compile-time-arguments = compile-time-arguments ;
                                                                                                                        shell-application = shell-application ;
                                                                                                                        planned-error = planned-error ;
                                                                                                                        visitor = visitor ;
                                                                                                                        unplanned-error = unplanned-error ;
                                                                                                                    }
                                                                                                            )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            OUT=/build/test
                                                                                                            COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON compile-time-arguments ) } )" || exit ${ builtins.toString error-unplanned }
                                                                                                            RUN_TIME_ARGUMENTS="$( cat ${ builtins.toFile "run-time-arguments.json" ( builtins.toJSON check-parameters.run-time-arguments ) } )" || exit ${ builtins.toString error-unplanned }
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
                                                                                                            echo -n ${ builtins.toString } > "$OUT/expected/status"
                                                                                                            mkdir --parents "$OUT/observed"
                                                                                                            exec 0<&-
                                                                                                            if failure ${ builtins.concatStringsSep " " check-parameters.run-time-arguments } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
                                                                                                            then
                                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                                            else
                                                                                                                echo -n "$?" > "$OUT/observed/status"
                                                                                                            fi
                                                                                                            diff --unified "$OUT/expected" "$OUT/observed"
                                                                                                        '' ;
                                                                                                }
                                                                                        )
                                                                                    ] ;
                                                                                imports = [ implementation ] ;
                                                                            } ;
                                                                } ;
                                                            testScript =
                                                                ''
                                                                    client.wait_for("network-online.target")
                                                                    client.success("${ test-script }/bin/test-script")
                                                                '' ;
                                                        } ;
                                                in
                                                    {
                                                        name = builtins.concatStringsSep "-" [ "check" ( builtins.toString order ) ] ;
                                                        order = check-parameters.order ;
                                                        value = ignore : value ;
                                                    } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
