{
    inputs =
        {
        } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        config-identity ? x : x ,
                        lib-identity ? x : x ,
                        options-identity ? x : x ,
                        pkgs-identity ? x : x
                    } :
                        let
                            implementation =
                                { lib , pkgs , ... } :
                                    let
                                        _lib = lib-identity lib ;
                                        _pkgs = pkgs-identity pkgs ;
                                        in
                                            {
                                                options =
                                                    options-identity
                                                        {
                                                            failure =
                                                                _lib.mkOption
                                                                    {
                                                                        default =
                                                                            {
                                                                                compile-time-arguments ? null ,
                                                                                shell-application ? _pkgs.writeShellApplication ,
                                                                                planned-error ? 176 ,
                                                                                visitor ? builtins.toJSON ,
                                                                                unplanned-error ? 118
                                                                            } :
                                                                                pkgs.writeShellApplication
                                                                                    {
                                                                                        name = "failure" ;
                                                                                        runtimeInputs = [ _pkgs.coreutils _pkgs.jq ] ;
                                                                                        text =
                                                                                            ''
                                                                                                COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON compile-time-arguments ) } )" || exit ${ builtins.toString unplanned-error }
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
                                                                                                exit ${ builtins.toString planned-error }
                                                                                            '' ;
                                                                                    } ;
                                                                        type = _lib.types.functionTo _lib.types.package ;
                                                                    } ;
                                                        } ;
                                            } ;
                            in
                                {
                                    check =
                                        {
                                            nixosTest ,
                                            obviated-by
                                        } :
                                        {
                                            compile-time-arguments ,
                                            shell-application ,
                                            planned-error ,
                                            visitor ,
                                            unplanned-error
                                        } :
                                        {
                                            run-time-arguments ? [ ]
                                        } :
                                            let
                                                test =
                                                    nixosTest
                                                        {
                                                            name = "failure" ;
                                                            nodes.client =
                                                                { config , pkgs , ... }  :
                                                                    let
                                                                        _config = config-identity config ;
                                                                        _pkgs = pkgs-identity pkgs ;
                                                                        in
                                                                            {
                                                                                environment.systemPackages =
                                                                                    [
                                                                                        (
                                                                                            pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "test-script" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            _pkgs.coreutils
                                                                                                            _pkgs.diffutils
                                                                                                            _pkgs.jq
                                                                                                            (
                                                                                                                _config.failure
                                                                                                                    {
                                                                                                                        compile-time-arguments = compile-time-arguments ;
                                                                                                                        shell-application = shell-application ;
                                                                                                                        planned-error = planned-error ;
                                                                                                                        visitor = null ;
                                                                                                                        unplanned-error = unplanned-error ;
                                                                                                                    }
                                                                                                            )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            OUT=/build/test
                                                                                                            COMPILE_TIME_ARGUMENTS="$( cat ${ builtins.toFile "compile-time-arguments.json" ( builtins.toJSON compile-time-arguments ) } )" || exit ${ builtins.toString unplanned-error }
                                                                                                            RUN_TIME_ARGUMENTS="$( cat ${ builtins.toFile "run-time-arguments.json" ( builtins.toJSON run-time-arguments ) } )" || exit ${ builtins.toString unplanned-error }
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
                                                                                                            echo -n ${ builtins.toString planned-error } > "$OUT/expected/status"
                                                                                                            mkdir --parents "$OUT/observed"
                                                                                                            if failure ${ builtins.concatStringsSep " " run-time-arguments } > "$OUT/observed/standard-output" 2> "$OUT/observed/standard-error"
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
                                                            testScript =
                                                                ''
                                                                    client.wait_for_unit("multi-user.target")
                                                                    client.succeed("test-script")
                                                                '' ;
                                                        } ;
                                                in
                                                    {
                                                        obviated-by = obviated-by ;
                                                        test = test ;
                                                        # nixosTest { name = "stooge" ; nodes = { } ; testScript = ''raise Exception '${ builtins.toJSON { obviated-by = obviated-by ; compile-time-arguments = compile-time-arguments ; planned-error = planned-error ; unplanned-error = unplanned-error ; } }' '' ; } ;#
                                                        type = "failure" ;
                                                    } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
