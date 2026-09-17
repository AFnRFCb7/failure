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
                        error-planned ? 188 ,
                        error-unplanned ? 142 ,
                        jq ,
                        mkDerivation ,
                        writeShellApplication ,
                        visitor
                    } :
                        let
                            _visitor = parameters.visitor.lib { default = path : value : let type = builtins.typeOf value ; in { path = path ; type = type ; value = if type == "lambda" then null else value ; } ; } ;
                            implementation =
                                compile-time-arguments :
                                    writeShellApplication
                                        {
                                            name = "failure" ;
                                            runtimeInputs = [ coreutils jq ] ;
                                            text =
                                                ''
                                                    export COMPILE_TIME_ARGUMENTS_JSON='${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON ( _visitor.implementation { } compile-time-arguments ) ) }'
                                                    if [[ -t 0 ]]
                                                    then
                                                        STANDARD_INPUT="$( cat )" || exit ${ builtins.toString error-unplanned }
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
                                                    exit ${ builtins.toString error-planned }
                                                '' ;
                                        } ;
                            parameters =
                                {
                                    coreutils = coreutils ;
                                    error-planned = error-planned ;
                                    error-unplanned = error-unplanned ;
                                    jq = jq ;
                                    mkDerivation = mkDerivation ;
                                    writeShellApplication = writeShellApplication ;
                                    visitor = visitor ;
                                } ;
                            in
                                {
                                    check =
                                        {
                                            compile-time-arguments ? null ,
                                            diffutil ,
                                            expected-standard-error ,
                                            run-time-arguments ? [ ]
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        let
                                                            test =
                                                                writeShellApplication
                                                                    {
                                                                        name = "test" ;
                                                                        runtimeInputs = [ coreutils yq-go ( implementation compile-time-arguments ) ] ;
                                                                        text =
                                                                            ''
                                                                                OUT="$1"
                                                                                touch "$OUT"
                                                                                mkdir --parents /build/test
                                                                                if failure ${ builtins.concatStringsSep " " run-time-arguments } > /build/test/standard-output 2> /build/test/standard-error
                                                                                then
                                                                                    STATUS="$?"
                                                                                else
                                                                                    STATUS="$?"
                                                                                fi
                                                                                STANDARD_OUTPUT="$( cat /build/test/standard-output )" || exit ${ builtins.toString error-unplanned }
                                                                                if [[ -n "$STANDARD_OUTPUT" ]]
                                                                                then
                                                                                    echo "We expected no standard output but we got $STANDARD_OUTPUT" >&2
                                                                                    exit ${ builtins.toString error-planned }
                                                                                fi
                                                                                if ! diff --unified ${ builtins.toFile "standard-error"  expected-standard-error } /build/test/standard-error
                                                                                then
                                                                                    echo "We expected standard error to be ${ builtins.toFile "standard-error" expected-standard-error } but it was:" >&2
                                                                                    cat /build/test/standard-error >&2
                                                                                    exit ${ builtins.toString error-planned }
                                                                                fi
                                                                                if [[ "$STATUS" != "64" ]]
                                                                                then
                                                                                    echo "We expected the status to be 64 but we got $STATUS" >&2
                                                                                    exit ${ builtins.toString error-planned }
                                                                                fi
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
