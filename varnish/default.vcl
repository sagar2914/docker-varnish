# vcl 4.0;

# backend default {
#   .host = "localhost:8000";
# }
#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

import std;
import directors;

# Default backend definition. Set this to point to your content server.
backend ap1 {
  .host = "nginx";
  .port = "80";
  .first_byte_timeout = 200s;
  .probe = {
         .url = "/";
         .interval = 30s;
         .timeout = 1 s;
         .window = 5;
         .threshold = 3;
         .initial = 1;
  }
}
# Another backend config
# backend ap2 {
#   .host = "127.0.0.1";
#   .port = "8081";
#   .first_byte_timeout = 200s;
#   .probe = {
#          .url = "/";
#          .interval = 5s;
#          .timeout = 1 s;
#          .window = 5;
#          .threshold = 3;
#          .initial = 1;
#   }
# }
acl purge_ip {
    "localhost";
    "127.0.0.1";
    // ""
}

sub vcl_init{
    new ws = directors.random();
    ws.add_backend(ap1, 1.0);
    # ws.add_backend(ap2, 1.0);
}


sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

#     std.log("vcl recv: "+req.request);

    if (req.restarts == 0) {
      if (req.http.x-forwarded-for) {
          set req.http.X-Forwarded-For =
          req.http.X-Forwarded-For + ", " + client.ip;
      } else {
          set req.http.X-Forwarded-For = client.ip;
      }
    }
    set req.backend_hint = ws.backend();
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PURGE" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method == "PURGE") {
         if (!client.ip ~ purge_ip) {
             #return(synth(405, "Not Found"));
             return(synth(403, "Not allowed"));
         }
         return (purge);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }
    if (req.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || req.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
        return (hash);
    }
    if (req.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
        unset req.http.Cookie;
        return (hash);
    }
    if (req.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
        return (hash);
    }
    if (req.url ~ "\.(css|js)$") {
        return (hash);
    }
    if (req.http.Authorization || req.http.Cookie ~ "(^|; )(__ac=|_ZopeId=)") {
        /* Not cacheable by default */
        return (pipe);
    }
    return (hash);
}


sub vcl_hash {
    hash_data(req.url);
    #if (req.http.host) {
    #    hash_data(req.http.host);
    #} else {
    #    hash_data(server.ip);
    #}
    return (lookup);
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
    if (beresp.ttl <= 0s ||
        beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
        /*
         * Mark as "Hit-For-Pass" for the next 60 minutes - 24 hours
         */
        if (bereq.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || bereq.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
        } elseif (bereq.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
            unset beresp.http.set-cookie;
            set beresp.do_stream = true;
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 60s;
        } elseif (bereq.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
        } elseif (bereq.url ~ "\.(css|js)$") {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 24h;
        } else {
            set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 1h;
        }
    }
    return (deliver);
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
  set resp.http.Access-Control-Allow-Origin = "*";
  set resp.http.Access-Control-Allow-Credentials = "true";
  
  if (req.method == "OPTIONS") {
      set resp.http.Access-Control-Max-Age = "1728000";
      set resp.http.Access-Control-Allow-Methods = "GET, POST, PUT, DELETE, PATCH, OPTIONS";
      set resp.http.Access-Control-Allow-Headers = "Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since";

      set resp.http.Content-Length = "0";
      set resp.http.Content-Type = "text/plain charset=UTF-8";
      set resp.status = 204;
  }
}

sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    synthetic ("Error");
    return (deliver);
}