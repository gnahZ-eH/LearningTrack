## Route Services

### Introduction

- CFAR app developers may wish to apply transformation or processing to requests before they reach an app. Common examples of use cases include authentication, rate limiting, and caching services. Route Services are a kind of Marketplace Service that developers can use to apply various transformations to app requests by binding an app’s route to a service instance. Through integrations with service brokers and, optionally, with the CFAR routing tier, providers can offer these services to developers with a familiar, automated, self-service, and on-demand user experience.

### Fully-Brokered Service

- In the fully-Brokered Service model, the CFAR router receives all traffic to apps in the deployment before any processing by the route service. Developers can bind a route service to any app, and if an app is bound to a route service, the CFAR router sends its traffic to the service. After the route service processes requests, it sends them back to the load balancer in front of the CFAR router. The second time through, the CFAR router recognizes that the route service has already handled them, and forwards them directly to app instances.

    ![](./img/route-services-fully-brokered.png)

- Advantages:
    - Developers can use a Service Broker to dynamically configure how the route service processes traffic to specific apps.
    - Adding route services requires no manual infrastructure configuration.
    - Traffic to apps that do not use the service makes fewer network hops because requests for those apps do not pass through the route service.
- Disadvantages:
    - Traffic to apps that use the route service makes additional network hops, as compared to the static model.