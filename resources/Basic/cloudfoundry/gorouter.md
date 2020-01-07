## gorouter
Gorouter来源于CloudFoundry，后文简称为router。它是整个平台的流量入口，负责分发所有的http请求到对应的instance。它在内存中维护了一张路由表，记录了域名与实例的对应关系，所谓的实例自动迁移，靠得就是这张路由表，某实例宕掉了，就从路由表中剔除，新实例创建了，就加入路由表。

Gorouter routes traffic coming into Cloud Foundry to the appropriate component, whether the request comes from an operator addressing the Cloud Controller or from an application user accessing an app running on a Diego Cell. Handling both platform and app requests with the same process centralizes routing logic and simplifies support for WebSockets and other types of traffic (for example, through HTTP CONNECT).

## Usage
Gorouter receives route updates through NATS. By default, routes that have not been updated in two minutes are pruned. Therefore, to maintain an active route, you must ensure that the route is updated at least every two minutes. The format of these route updates is as follows: