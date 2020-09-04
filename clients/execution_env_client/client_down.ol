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
    request.name = "reader"
    request.instance = 1
    down@Env( request )(  )

}