/**
 * Copyright (c) 2015 Herman Bergwerf
 *
 * This file is part of MolView Web.
 *
 * MolView Web is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MolView Web is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with MolView Web.  If not, see <http://www.gnu.org/licenses/>.
 */

// Load the http module to create an http server.
var http = require('http')

// Configure our HTTP server to respond with Hello World to all requests.
var server = http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/plain'})
  response.end('Hello World\n')
})

// Listen on port 8080, IP defaults to 127.0.0.1
server.listen(8080)

// Put a friendly message on the terminal.
console.log('Server running at http://127.0.0.1:8080/')
