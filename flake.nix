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
                                                    RUNTIME_ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq -R . | jq -s . )" || exit ${ builtins.toString error-unplanned }
                                                    export RUNTIME_ARGUMENTS_JSON
                                                    yq --null-input --prettyPrint '{ "compile-time-arguments" : ${ _visitor compile-time-arguments } }' >&2
                                                    exit ${ builtins.toString error-planned }
                                                '' ;
                                        } ;
                            in
                                {
                                    check =
                                        {
                                            compile-time-arguments ,
                                            expectation ,
                                            run-time-arguments ,
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
                                                                                STANDARD_OUTPUT="$( < /build/test/standard-output )" || exit 64
                                                                                if [[ -n "$STANDARD_OUTPUT" ]]
                                                                                then
                                                                                    echo "We expected no standard output but we got $STANDARD_OUTPUT" >&2
                                                                                    exit 64
                                                                                fi
                                                                                EXPECTED_STANDARD_ERROR="${ expected }"
                                                                                OBSERVED_STANDARD_ERROR="$( < /build/test/standard-error )" || exit 64
                                                                                if [[ "$EXPECTED_STANDARD_ERROR" != "$OBSERVED_STANDARD_ERROR" ]]
                                                                                then
                                                                                    echo "We expected standard error to be $EXPECTED_STANDARD_ERROR but it was $OBSERVED_STANDARD_ERROR" >&2
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
