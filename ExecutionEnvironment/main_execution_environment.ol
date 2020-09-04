include "public/interfaces/OperationalInterface.iol"
include "string_utils.iol"
include "console.iol"
include "time.iol"
include "exec.iol"
include "file.iol"
include "ini_utils.iol"
include "runtime.iol"
include "zip_utils.iol"

interface InternalInterface {
    RequestResponse:
        getPort( void )( int ) throws PortNotAvailable,
        freePort( int )( void ) 
}

execution{ concurrent }

outputPort Jocker {
    Location: "socket://localhost:8008"
	Protocol: sodep
	RequestResponse:
		build,
		images,
        inspectContainer,
		createContainer,
		startContainer,
		stopContainer,
		containers,
		removeImage,
		removeContainer,
		logs

}

outputPort MySelf {
    Interfaces: InternalInterface
}

inputPort MySelf {
    Location: "local"
    Protocol: sodep
    Interfaces: InternalInterface
}

inputPort OperationalInputPort {
    Location: "auto:ini:/Locations/OperationalInputPort:file:locations.ini"
    Protocol: sodep
    Interfaces: OperationalInterface
}

outputPort Test {
    Protocol: sodep
    RequestResponse: check
}

constants {
    PORT_BASE = 10000,
    PORT_MAX = 1000,
    PORTS_JSON = "ports.json"
}

define __prepare_dockerfile {
	dockerfile = "FROM jolielang/jolie\n"
	+ "RUN mkdir micro\n"
	+ "WORKDIR micro\n"
	+ "ADD . .\n"
    + "CMD jolie --trace " + name + ".jap\n"
	undef( file ) 
	file.filename = wkdir + "Dockerfile"
	file.content -> dockerfile
	writeFile@File( file )()
}

define __prepare_docker_image {

    // Preparing tar files
    token = new
    wkdir = "tmp/" + token + "/"
    mkdir@File( wkdir )(  )

    undef( wf )
    wf << {
        filename = wkdir + "file.zip",
        content << request.zip,
        format = "binary"
    }
    writeFile@File( wf )(  )
    unzip@ZipUtils( { filename = wkdir + "file.zip", targetPath = wkdir } )(  )
    delete@File( wkdir + "file.zip" )(  )

    __prepare_dockerfile

   
	tarfile = wkdir + "docker.tar"
	
    exec_rq = "tar";
    with( exec_rq ) {
        .args[0] = "-cf";
        .args[1] = "docker.tar";
        .args[2] = ".";
        .workingDirectory = wkdir
    };
    exec@Exec( exec_rq )( exec_rs );


	// * Loading file tar and prepare to build
	undef( file )
  	file.filename = tarfile;
	file.format = "binary";
	readFile@File(file)(rqImg.file);

	rqImg.dockerfile = "./Dockerfile";
  	rqImg.t = image_name


	println@Console("Building " + rqImg.t + ":latest image")();
	// send it to Docker
	build@Jocker(rqImg)(build_response);
    println@Console("Done")()
    deleteDir@File( wkdir )(  )
}

define __write_port_map {
        wf << {
            filename = PORTS_JSON,
            format = "json",
            content.ports << global.exposed_ports.ports 
        }
        writeFile@File( wf )(  )
}
 
init {
    getLocalLocation@Runtime()( MySelf.location )
    exists@File( "tmp" )( exist_tmp )
    if ( !exist_tmp ) { mkdir@File( "tmp" )() }
    exists@File( PORTS_JSON )( exist_port_json )
    if ( !exist_port_json ) {
        for( i = 0, i < PORT_MAX, i++ ) {
            global.exposed_ports.ports.port[ i ] << {
                number = PORT_BASE + i,
                enabled = false
            }
        }
        __write_port_map
    } else {
        readFile@File( { filename = PORTS_JSON, format="json" } )( global.exposed_ports )
    }
    println@Console( "Execution environment is running..." )(  )
} 


main {
    [ up( request )( response ) {
        scope( create_container ) {
            install( PortNotAvailable => throw( StartingError ) )
            install( NoSuchImage => 
                __prepare_docker_image; 
                createContainer@Jocker( cntCreate_rq )( cntCreate_rs ) 
            )
            toLowerCase@StringUtils( request.name )( name )
            image_name = name + "_img:latest";
            container_name = name + request.instance

            with ( cntCreate_rq ) {
                .name = container_name;
                .Image = image_name;
                for ( p in request.exposed_ports) {
                    .ExposedPorts.( p.number + "/tcp") = obj.("{}");
                    getPort@MySelf()( port );
                    .HostConfig.PortBindings.( p.number + "/tcp")._.HostIp = "localhost";
                    .HostConfig.PortBindings.( p.number + "/tcp")._.HostPort = string( port )
                    response.exposed_ports[ #response.exposed_ports ] << {
                        number = p.number,
                        map = port
                    }
                }
            }
            ;
            createContainer@Jocker( cntCreate_rq )( cntCreate_rs )
        }

        // starting container
        println@Console("Starting container " + container_name )();
        startCnt_rq.id = container_name;
        startContainer@Jocker( startCnt_rq )();
        println@Console("Done.")()
    }]

    [ down( request )( response ) {
        println@Console("Stopping container " +  request.name + request.instance )()
        container_name = request.name + request.instance
        stopCnt_rq.id = container_name
        inspectContainer@Jocker( stopCnt_rq )( inspection )
        foreach ( p : inspection.HostConfig.PortBindings ) {          
            freePort@MySelf( int( inspection.HostConfig.PortBindings.( p ).HostPort ) )()
        }
        stopContainer@Jocker( stopCnt_rq )()
        println@Console( "Done" )(  )
        println@Console("Removing container " +  request.name + request.instance )()
        removeContainer@Jocker( stopCnt_rq )( )
        println@Console( "Done" )(  )
        
    }] 

    [ getPort( request )( response ) {
         synchronized( port_selection ) {
            found = false
            count = 0
            while( !found && count < #global.exposed_ports.ports.port ) {
                if ( !global.exposed_ports.ports.port[ count ].enabled ) {
                    found = true 
                    response = global.exposed_ports.ports.port[ count ].number
                    global.exposed_ports.ports.port[ count ].enabled = true
                }
                count++
            }
             if ( !found ) {
                throw( PortNotAvailable )
            } else {
                __write_port_map
            }
         }
        
    }]

    [ freePort( request )( response ) {
         synchronized( port_selection ) {
            found = false
            count = 0
            while( !found && count < #global.exposed_ports.ports.port ) {
                if ( global.exposed_ports.ports.port[ count ].number == request ) {
                    found = true 
                    global.exposed_ports.ports.port[ count ].enabled = false
                }
                count++
            }
            if ( found ) {
                __write_port_map
            }
         }
        
    }]
}