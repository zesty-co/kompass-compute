PROBLEM_KEYS=$(find . -type f -name '*.tpl' | xargs grep -Eo '{{-?[[:space:]]*define[[:space:]]*"[^"]+"' | sed -E 's/.*define[[:space:]]*"([^"]+)".*/\1/' | grep -v '^kompass-compute\.' )

if [ -n "${PROBLEM_KEYS}" ]; then
    echo "Some template variables do not start with 'kompass-compute.' prefix."
    echo ${PROBLEM_KEYS}
    exit 1
fi