<!--**OpenFTP** Compliance Outline  
Created for the *Beta 3* release and onwards
====-->

This document exists to describe the necessary features required in a program for it to be considered compliant with the OpenFTP Beta 3 (and onwards) standard.

There are multiple 'levels' of compliance, each ascending level requires all the compliance features of the previous levels, *as well as* the newly specified requirements.


Terminology:
====

+ P2S = Peer-to-Server: Any operation classed as P2S is specifically designed to only work between a designated Client program and Server program, using the P2S protocols.
+ P2P = Peer-to-Peer: Any operation classed as P2P is specifically designed to only work between two clients with this capability. P2S and P2P are not cross-compatible
+ P2A = Peer-to-All: Any operation that has been built in such a way that it does not require a client-server distinction. (Currently not implemented)
+ GERTi = [Globally Engineered Routing Technology (Internal)](https://github.com/GlobalEmpire/GERT)

Compatibility
====

Programs must include their compatibility in the program, that is the version they were designed to work with. In the event that a version is backwards compatible, it will take the compatibility rating of the earliest version it is compatible with. 



---

Level 1 Prerequisites:
> Access to GERTi, installed in a functional configuration.

> Access to a serialization library that is compatible with the OpenOS Table Serialization library.

> Any error codes, defined by *any result* in the program that is not `return true, 0`, signifying that the command was not fully executed or completed, must be identical to the error codes found in the official standard, for ease of bugfixing and cross-compatibility, and defined at the beginning of the file for ease of identification. *It is permitted to omit any errors which could never possibly occur because they are caused by a function that you have not included in your program.*

> A local variable must be declared at the start of the program, which contains the port number that the program will use to open sockets. This is for ease of adjustment in custom setups. 

> A local variable must be declared that contains the compatibility string of the program. For Beta 3, this string must be "Beta3.0" 

> For all timers, it is recommended to have a timeout of 15 seconds. Due to the way the functions work, a timeout of 5 seconds is likely more than sufficient, but 15 has been chosen for *Beta 3*



Level 1 Features:
1. File Send (P2S) without encryption or user credentials
2. File Request (P2S) without encryption or user credentials
3. Package Request (P2S) without encryption or user credentials.

---

Level 2 Prerequisites:

> Access to the Java/Scala cipher library is required for 128bit AES encryption in CBC mode, the SHA256 hash function, ecdh, ecdsa, and asymmetric Keypair generation 


---

Client-Side P2S Implementation Compliance:

Communication between the Client and the Server must happen in several phases.

1.  - The client application must request the server's operating version using `GERTi.send(ServerAddress, "GetVersion")`, and then listen for the response, which will arrive with the event "GERTData", with the information in the fourth parameter, and the Origin Address (the sender) in the second. It is recommended to filter out events not triggered by the server, A.K.A filter by the Origin Address. 
    - There are only 3 outcomes: 
        - `true, 0` if the server has responded and the Version is identical to your compatibility string, or simply continue if you haven't separated the server verification into its own function.
        - `false, INCOMPATIBLESERVER` if the server has responded, but the response is different from your compatibility String.
        - `false, INVALIDSERVERADDRESS` if the server responded, but no data was supplied in the fourth parameter
    - The server address must be checked to ensure it isnt nil, and `false, NILSERVERADDRESS` must be returned if it is.  
2.  - The client application must now create a hash table with the following key/values pairs:
        - "Mode" which contains the operation
        - "Name" which contains the name of the file to send or to request if it exists
        - "Size" which contains the size of the file in bytes (if sending a file)
        - "User" which contains the unencrypted username (if requesting any operations that require credentials for an existing user)
        - "PasswordSignature" which contains an ecdsa signature made from the Password and the Private key (if applicable)
        - "PuKey" which contains the serialized public key (if applicable)