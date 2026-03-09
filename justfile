# Default recipe to build all test data
tests-data: _bigdata_json _bigdata_yml _random_lines_txt

_bigdata_json:
    @mkdir -p tests/data
    @if [ ! -f tests/data/bigdata.json ]; then \
        curl -L --progress-bar -o tests/data/bigdata.json \
        "https://raw.githubusercontent.com/miloyip/nativejson-benchmark/master/data/canada.json"; \
    fi

_bigdata_yml:
    @mkdir -p tests/data
    base64 /dev/urandom | head --bytes $(( 5*1024*1024 )) > tests/data/bigdata.yml; \

_random_lines_txt:
    @mkdir -p tests/data
    dd if=/dev/urandom bs=1k count=1001024 | tr -c '\n' 'a-zA-Z0-9' > tests/data/random_lines.txt; \

