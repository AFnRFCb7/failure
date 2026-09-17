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
                        writeShellApplication ,
                        visitor
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
                                                            export COMPILE_TIME_ARGUMENTS_JSON='${ builtins.toFile "compile-time-arguments.json" implementation-parameters.compile-time-arguments }'
                                                            if [[ -t 0 ]]
                                                            then
                                                                STANDARD_INPUT="$( cat )" || exit ${ builtins.toString root-parameters.error-unplanned }
                                                                jq \
                                                                    --null-input \
                                                                    --prettyPrint \
                                                                    --argjson "$COMPILE_TIME_ARGUMENTS" \
                                                                    --arg STANDARD_INPUT="$STANDARD_INPUT" \
                                                                    '{
                                                                        "arguments" :
                                                                            {
                                                                                "compile" : env(COMPILE_TIME_ARGUMENTS_JSON) ,
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
                                                                    --prettyPrint \
                                                                    --argjson "$COMPILE_TIME_ARGUMENTS" \
                                                                    '{
                                                                        "arguments" :
                                                                            {
                                                                                "compile" : env(COMPILE_TIME_ARGUMENTS_JSON) ,
                                                                                "run" : $ARGS.positional
                                                                            } ,
                                                                        "inputs" : { }
                                                                    }' -- "$@" >&2
                                                            fi
                                                            exit ${ builtins.toString root-parameters.error-planned }
                                                        '' ;
                                                } ;
                                    root-parameters =
                                        {
                                            coreutils = coreutils ;
                                            error-planned = visitor { int = path : value : builtins.toString value ; } error-planned ;
                                            error-unplanned = visitor { init = path : value : builtins.toString value ; } error-unplanned ;
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
                                            run-time-arguments ? [ ] ,
                                            standard-error ,
                                            standard-input
                                        } :
                                            let
                                                check-parameters =
                                                    {
                                                        compile-time-arguments = compile-time-arguments ;
                                                        diffutils = diffutils ;
                                                        mkDerivation = mkDerivation ;
                                                        run-time-arguments = run-time-arguments ;
                                                        standard-error =
                                                            visitor
                                                                {
                                                                    path = path : value : value ;
                                                                    string = path : value : builtins.toFile "standard-error" value ;
                                                                } standard-error ;
                                                        standard-input = standard-input ;
                                                    } ;
                                                in
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
                                                                                runtimeInputs = [ root-parameters.coreutils ( implementation check-parameters.compile-time-arguments ) ] ;
                                                                                text =
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        mkdir --parents "$OUT/expected"
                                                                                        ln --symbolic ${ check-parameters.standard-error } "$OUT/expected/standard-error"
                                                                                        echo -n "" > "$OUT/expected/standard-output"
                                                                                        echo -n ${ root-parameters.error-planned } > "$OUT/expected/status"
                                                                                        mkdir --parents "$OUT/observed"
                                                                                        if failure ${ builtins.concatStringsSep " " check-parameters.run-time-arguments } ${ if builtins.typeOf check-parameters.standard-input == "path" then "< ${ check-parameters.standard-input }" else "" } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
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
                                                            src = ./. ;
                                                        } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
