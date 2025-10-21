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
                        error-planned ? 64 ,
                        error-unplanned ? 65 ,
                        jq ,
                        mkDerivation ,
                        writeShellApplication ,
                        visitor ,
                        yq-go
                    } :
                        let
                            _visitor = visitor.lib { default = path : value : let type = builtins.typeOf value ; in { path = path ; type = type ; value = if type == "lambda" then null else value ; } ; } ;
                            implementation =
                                compile-time-arguments :
                                    writeShellApplication
                                        {
                                            name = "failure" ;
                                            runtimeInputs = [ coreutils jq yq-go ] ;
                                            text =
                                                ''
                                                    if [ -t 0 ]
                                                    then
                                                        HAS_STANDARD_INPUT=false
                                                        STANDARD_INPUT="empty"
                                                    else
                                                        HAS_STANDARD_INPUT=true
                                                        STANDARD_INPUT="$( cat )" || exit ${ builtins.toString error-unplanned }
                                                    fi
                                                    export HAS_STANDARD_INPUT
                                                    export STANDARD_INPUT
                                                    export COMPILE_TIME_ARGUMENTS_JSON='${ builtins.toJSON ( _visitor.implementation { } compile-time-arguments ) }'
                                                    RUN_TIME_ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq -R . | jq -s . )" || exit ${ builtins.toString error-unplanned }
                                                    export RUN_TIME_ARGUMENTS_JSON
                                                    echo "$0" >&2
                                                    yq \
                                                        eval \
                                                        --null-input \
                                                        --prettyPrint \
                                                        '{ "compile-time-arguments" : env(COMPILE_TIME_ARGUMENTS_JSON) , "has-standard-input" : env(HAS_STANDARD_INPUT) , "run-time-arguments" : env(RUN_TIME_ARGUMENTS_JSON) , "standard-input" : env(STANDARD_INPUT) }' >&2
                                                    exit ${ builtins.toString error-planned }
                                                '' ;
                                        } ;
                            in
                                {
                                    check =
                                        {
                                            compile-time-arguments ? null ,
                                            diffutil ,
                                            expected-standard-error ,
                                            run-time-arguments ? [ ] ,
                                            standard-input ? null
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
                                                                                if failure ${ builtins.concatStringsSep " " run-time-arguments }${ if builtins.typeOf standard-input == "null" then "" else " < ${ builtins.toFile "standard-input" standard-input }" }> /build/test/standard-output 2> /build/test/standard-error
                                                                                then
                                                                                    STATUS="$?"
                                                                                else
                                                                                    STATUS="$?"
                                                                                fi
                                                                                STANDARD_OUTPUT="$( < /build/test/standard-output )" || exit 64
                                                                                if [[ -n "$STANDARD_OUTPUT" ]]
                                                                                then
                                                                                    echo "We expected no standard output but we got $STANDARD_OUTPUT" >&2
                                                                                    exit 64
                                                                                fi
                                                                                if ! diff --unified ${ builtins.toFile "standard-error"  expected-standard-error } /build/test/standard-error
                                                                                then
                                                                                    echo "We expected standard error to be ${ builtins.toFile "standard-error" expected-standard-error } but it was:" >&2
                                                                                    cat /build/test/standard-error >&2
                                                                                    exit 64
                                                                                fi
                                                                                if [[ "$STATUS" != "64" ]]
                                                                                then
                                                                                    echo "We expected the status to be 64 but we got $STATUS" >&2
                                                                                    exit 64
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
