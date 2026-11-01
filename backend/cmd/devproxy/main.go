// One origin for local development: Caddy's job in production. /api and
// /ws go to the Go server, everything else to the Flutter dev server.
// Sign-in with revoked needs this: the client id is the origin, and the
// address the revoked server returns to has to sit on it.
package main

import (
	"flag"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
)

func main() {
	listen := flag.String("listen", ":8099", "address to serve on")
	api := flag.String("api", "http://127.0.0.1:8090", "the Go server")
	web := flag.String("web", "http://127.0.0.1:3010", "the Flutter dev server")
	flag.Parse()

	apiURL, err := url.Parse(*api)
	if err != nil {
		log.Fatal(err)
	}
	webURL, err := url.Parse(*web)
	if err != nil {
		log.Fatal(err)
	}
	toAPI := httputil.NewSingleHostReverseProxy(apiURL)
	toWeb := httputil.NewSingleHostReverseProxy(webURL)

	log.Printf("dev proxy on %s -> api %s, web %s", *listen, *api, *web)
	log.Fatal(http.ListenAndServe(*listen, http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			if strings.HasPrefix(r.URL.Path, "/api/") || strings.HasPrefix(r.URL.Path, "/ws/") {
				toAPI.ServeHTTP(w, r)
				return
			}
			toWeb.ServeHTTP(w, r)
		})))
}
