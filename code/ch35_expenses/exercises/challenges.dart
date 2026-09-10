// Study 35 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// Every one of them is a `Handler`, which is `FutureOr<Response> Function`
// `(Request)` and nothing else. So none of these challenges needs a port, a
// socket, or a `setUp` that binds anything — the tests call your function the
// way any other function is called. That is the whole of what this study bought.

import 'package:shelf/shelf.dart';

/// 1. A handler that always says the same thing.
///
///    Answers `200` with [body] at every path, for every method. `Response.ok`
///    is the constructor; the body goes in as a `String`.
///
///    Nothing computes a `content-length` here and one arrives anyway, because
///    `shelf` buffers the body to work it out. The eighteen-line version in
///    this study did not, and quietly shipped `transfer-encoding: chunked`.
Handler always(String body) => throw UnimplementedError('1');

/// 2. Routing, by hand, so that study 37 can take it away again.
///
///    Answers with the handler [routes] has for the request's path, or with
///    [otherwise] when it has none. The path to match on is
///    `request.url.path` — note that `Request.url` is **relative**, so `/` is
///    the empty string and `/expenses` is `'expenses'`, with no leading slash.
///
///    A handler that picks a handler is still a handler. That is the property
///    `shelf_router` is built out of, and doing it once by hand is how you find
///    out there was nothing magic in it.
Handler byPath(Map<String, Handler> routes, {required Handler otherwise}) =>
    throw UnimplementedError('2');

/// 3. A handler that wraps a handler.
///
///    Answers `405 Method Not Allowed` to anything that is not a `GET`, with an
///    `allow: GET` header, and hands everything else to [inner] untouched. The
///    header goes in `Response`'s `headers` map.
///
///    `405` and not `404`: the path exists, and the method is the part that was
///    wrong. `allow` is how the response says which methods would have worked,
///    and a client that reads it does not have to guess.
///
///    A function that takes a handler and answers a handler is middleware. You
///    have now written one, before the word arrives in study 37.
Handler onlyGet(Handler inner) => throw UnimplementedError('3');
