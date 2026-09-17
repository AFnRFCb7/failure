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
                                            error-planned = _visitor { int = path : value : builtins.toString value ; } error-planned ;
                                            error-unplanned = _visitor { init = path : value : builtins.toString value ; } error-unplanned ;
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
                                            expected-standard-error ,
                                            mkDerivation ,
                                            run-time-arguments ? [ ] ,
                                            standard-input
                                        } :
                                            let
                                                check-parameters =
                                                    {
                                                        compile-time-arguments = compile-time-arguments ;
                                                        diffutils = diffutils ;
                                                        expected-standard-error = expected-standard-error ;
                                                        mkDerivation = mkDerivation ;
                                                        run-time-arguments = runtime-arguments ;
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
                                                                                name = "test" ;
                                                                                runtimeInputs = [ root-parameters.coreutils ( implementation check-parameters.compile-time-arguments ) ] ;
                                                                                text =
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        mkdir --parents "$OUT/expected"
                                                                                        ln --symbolic ${ check-parameters.standard-error } "$OUT/expected/standard-error"
                                                                                        ln --symbolic ${ check-parameters.standard-output } "$OUT/expected/standard-output"
                                                                                        ln --symbolic ${ check-parameters.status } "$OUT/expected/status"
                                                                                        mkdir --parents "$OUT/observed"
                                                                                        if failure ${ builtins.concatStringsSep " " check-parameters.run-time-arguments } ${ if builtins.typeOf check-parameters.standard-input == "path" then "< ${ check-parameters.standard-input }" else "" } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
                                                                                        then
                                                                                            echo "$?" > "$OUT/observed/status"
                                                                                        else
                                                                                            echo "$?" > "$OUT/observed/status"
                                                                                        fi
                                                                                        diff --unified "$OUT/expected" "$OUT/observed"
                                                                                    '' ;
                                                                            } ;
                                                                    in
                                                                        ''
                                                                            ${ test }/bin/test "$out"
                                                                        '' ;
                                                            name = "check" ;
                                                            src = ./. ;
                                                        } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
