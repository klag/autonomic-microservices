include "../../ExecutionEnvironment/public/interfaces/OperationalInterface.iol"
include "file.iol"
include "zip_utils.iol"
include "converter.iol"

outputPort Env {
    Location: "socket://localhost:9000"
    Protocol: sodep
    Interfaces: OperationalInterface
}

main {
    readFile@File( { filename = "reader_single.jap", format = "binary" } )( japfile )
    zip_rq.("reader.jap") = japfile;
    readFile@File( { filename = "lib/commons.jap", format = "binary" } )( commons )
    zip_rq.("lib/commons.jap") = commons;
    stringToRaw@Converter("[Locations]\nAdmin=socket://localhost:8000\nReader=socket://localhost:8001")(inifile )
    zip_rq.("readerconfig.ini") = inifile 
    zip@ZipUtils( zip_rq )( request.zip )
    request.exposed_ports[ 0 ].number = 8000
    request.exposed_ports[ 1 ].number = 8001
    request.name = "reader"
    request.instance = 1
    up@Env( request )(  )

}