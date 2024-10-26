{
  description = "NixCon 2024 - NixOS on garnix: Production-grade hosting as a game";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.garnix-lib = {
    url = "github:garnix-io/garnix-lib";
    inputs = {
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, garnix-lib, flake-utils }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          garnix-lib.nixosModules.garnix
          self.nixosModules.nixcon-garnix-player-module
          ({ pkgs, ... }: {
            playerConfig = {
              # Your github user:
              githubLogin = "oscar-schwarz";
              # You only need to change this if you changed the forked repo name.
              githubRepo = "nixcon-2024-player-template";
              # The nix derivation that will be used as the server process. It
              # should open a webserver on port 8080.
              # The port is also provided to the process as the environment variable "PORT".
              webserver =
                let
                  pyFile = ''
                    #!${pkgs.python3}/bin/python3
                    import http.server                                                            
                    import socketserver                                                           
                                                                                                
                    PORT = 8080  # You can change this to any port you prefer                     
                                                                                                
                    # Handler to serve files from the current directory                           
                    class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):                       
                      def do_GET(self):                                                         
                          if self.path == "/":                                                  
                              self.send_response(200)                                           
                              self.send_header("Content-type", "text/html")                     
                              self.end_headers()                                                
                              self.wfile.write(b"Hello, world! This is a 200 OK response.")     
                          else:                                                                 
                              self.send_response(404)  # Not found for other paths.             
                              self.end_headers()                                                       
                    # Setting up the HTTP server                                                  
                    with socketserver.TCPServer(("", PORT), SimpleHTTPRequestHandler) as httpd:                    
                        print(f"Serving at port {PORT}")                                          
                        httpd.serve_forever()

                  '';
                in
                pkgs.stdenv.mkDerivation {
                  name = "start-webserver";
                  src = ./.;
                  unpackPhase = "true";
                  buildPhase = ":";
                  installPhase = ''
                    mkdir -p $out/bin
                    echo -e """${pyFile}""" > $out/bin/start-webserver
                    chmod +x $out/bin/start-webserver
                  '';
                };
              # If you want to log in to your deployed server, put your SSH key
              # here:
              sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENriTFSJUHgHp+fGE2FjssfvIl6DoCTxLZj5I0ihjf4";
            };
          })
        ];
      };

      nixosModules.nixcon-garnix-player-module = ./nixcon-garnix-player-module.nix;
      nixosModules.default = self.nixosModules.nixcon-garnix-player-module;

      # Remove before starting the workshop - this is just for development
      #checks = import ./checks.nix { inherit nixpkgs self; };
    };
}
