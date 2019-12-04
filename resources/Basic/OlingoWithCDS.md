## A Full Process
---
* Provide a provider class and specify the superclass `org.apache.olingo.commons.api.edm.provider.CsdlAbstractEdmProvider`

Edm is the abbreviation for Entity Data Model. Accordingly, we understand that the CsdlEdmProvider is supposed to provide static descriptive information.

1.   The Entity Model of the service can be defined in the EDM Provider. The EDM model basically defines the available EntityTypes and the relation between the entities. An EntityType consists of primitive, complex or navigation properties. The model can be invoked with the Metadata Document request. **This is information is provided by mode.cds in db folder and service.cds in srv folder, after the cds complier' work, the edmx file is generated in /resources/edxm folder**

2. **getEntityType()** Here we declare the EntityType “Product” and a few of its properties

    * **getEntitySet()** Here we state that the list of products can be called via the EntitySet “Products”
    * **getEntityContainer()** Here we provide a Container element that is necessary to host the EntitySet.
    * **getSchemas()** The Schema is the root element to carry the elements.
    * **getEntityContainerInfo()** Information about the EntityContainer to be displayed in the Service Document

The metadata files are in `resources/edxm/*.xml`, and are loaded and parsed by function `ServiceHelper.loadMetadataFiles()`

---
* Whenever the URL is fired, Olingo will invoke the `EntityCollectionProcessor `implementation of our OData service. Then our `EntityCollectionProcessor` implementation is expected to provide a list of data.

    Create a Java class `DemoEntityCollectionProcessor` that implements the interface `org.apache.olingo.server.api.processor.EntityCollectionProcessor`

The `readEntityCollection(...)` method is used to “read” the data in the backend (this can be e.g. a database) and to deliver it to the user who calls the OData service.


**`The method signature`**:

The “request” parameter contains raw HTTP information. It is typically used for creation scenario, where a request body is sent along with the request.

With the second parameter, the “response” object is passed to our method in order to carry the response data. So here we have to set the response body, along with status code and content-type header.

The third parameter, the “uriInfo”, contains information about the relevant part of the URL. This means, the segments starting after the service name.

**`Sample`**:
```java
public void readEntityCollection(ODataRequest request, ODataResponse response, UriInfo uriInfo, ContentType responseFormat)
    throws ODataApplicationException, SerializerException {

    // 1st we have retrieve the requested EntitySet from the uriInfo object (representation of the parsed service URI)
    List<UriResource> resourcePaths = uriInfo.getUriResourceParts();
    UriResourceEntitySet uriResourceEntitySet = (UriResourceEntitySet) resourcePaths.get(0); // in our example, the first segment is the EntitySet
    EdmEntitySet edmEntitySet = uriResourceEntitySet.getEntitySet();

    // 2nd: fetch the data from backend for this requested EntitySetName
    // it has to be delivered as EntitySet object
    EntityCollection entitySet = getData(edmEntitySet);

    // 3rd: create a serializer based on the requested format (json)
    ODataSerializer serializer = odata.createSerializer(responseFormat);

    // 4th: Now serialize the content: transform from the EntitySet object to InputStream
    EdmEntityType edmEntityType = edmEntitySet.getEntityType();
    ContextURL contextUrl = ContextURL.with().entitySet(edmEntitySet).build();

    final String id = request.getRawBaseUri() + "/" + edmEntitySet.getName();
    EntityCollectionSerializerOptions opts = EntityCollectionSerializerOptions.with().id(id).contextURL(contextUrl).build();
    SerializerResult serializerResult = serializer.entityCollection(serviceMetadata, edmEntityType, entitySet, opts);
    InputStream serializedContent = serializerResult.getContent();

    // Finally: configure the response object: set the body, headers and status code
    response.setContent(serializedContent);
    response.setStatusCode(HttpStatusCode.OK.getStatusCode());
    response.setHeader(HttpHeader.CONTENT_TYPE, responseFormat.toContentTypeString());
}

private EntityCollection getData(EdmEntitySet edmEntitySet){

   EntityCollection productsCollection = new EntityCollection();
   // check for which EdmEntitySet the data is requested
   if(DemoEdmProvider.ES_PRODUCTS_NAME.equals(edmEntitySet.getName())) {
       List<Entity> productList = productsCollection.getEntities();

       // add some sample product entities
       final Entity e1 = new Entity()
          .addProperty(new Property(null, "ID", ValueType.PRIMITIVE, 1))
          .addProperty(new Property(null, "Name", ValueType.PRIMITIVE, "Notebook Basic 15"))
          .addProperty(new Property(null, "Description", ValueType.PRIMITIVE,
              "Notebook Basic, 1.7GHz - 15 XGA - 1024MB DDR2 SDRAM - 40GB"));
      e1.setId(createId("Products", 1));
      productList.add(e1);

      final Entity e2 = new Entity()
          .addProperty(new Property(null, "ID", ValueType.PRIMITIVE, 2))
          .addProperty(new Property(null, "Name", ValueType.PRIMITIVE, "1UMTS PDA"))
          .addProperty(new Property(null, "Description", ValueType.PRIMITIVE,
              "Ultrafast 3G UMTS/HSDPA Pocket PC, supports GSM network"));
      e2.setId(createId("Products", 1));
      productList.add(e2);

      final Entity e3 = new Entity()
          .addProperty(new Property(null, "ID", ValueType.PRIMITIVE, 3))
          .addProperty(new Property(null, "Name", ValueType.PRIMITIVE, "Ergo Screen"))
          .addProperty(new Property(null, "Description", ValueType.PRIMITIVE,
              "19 Optimum Resolution 1024 x 768 @ 85Hz, resolution 1280 x 960"));
      e3.setId(createId("Products", 1));
      productList.add(e3);
   }

   return productsCollection;
}
```

### **In CDS Service**

DataProvider will provide the data, and user cdsHandler to process, this is like the spring aop, means that we can add the custom logic in the handler

```java
CdsODataHandler cdsHandler = findOrCreateCdsHandler(requestContext.getServiceCatalog(),
						request.getEvent(), request.getService(), request.getEntity());
```
The `request.*` method is annotitate like this:
```java
@After(event = CdsService.EVENT_READ, entity = Services.CATALOG_SERVICE_AUTHORS)
```
To get data (CRUD): 
```
cdsHandler.process(request, requestContext);
```
---
* Create a new package myservice.mynamespace.web. Create Java class with name `DemoServlet` that inherits from `HttpServlet`.

Override the `service()` method. Basically, what we are doing here is to create an `ODataHttpHandler`, which is a class that is provided by Olingo. It receives the user request and if the URL conforms to the OData specification, the request is delegated to the processor implementation of the OData service. This means that the handler has to be configured with all processor implementations that have been created along with the OData service (in our example, only one processor). Furthermore, the `ODataHttpHandler` needs to carry the knowledge about the `CsdlEdmProvider`.

**In CDS Service, this is exist in `CdsODataV4Servlet`**

```java
public class DemoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = LoggerFactory.getLogger(DemoServlet.class);

    protected void service(final HttpServletRequest req, final HttpServletResponse resp) throws ServletException, IOException {
        try {
        // create odata handler and configure it with CsdlEdmProvider and Processor
        OData odata = OData.newInstance();
        ServiceMetadata edm = odata.createServiceMetadata(new DemoEdmProvider(), new ArrayList<EdmxReference>());
        ODataHttpHandler handler = odata.createHandler(edm);
        handler.register(new DemoEntityCollectionProcessor());

        // let the handler do the work
        handler.process(req, resp);
        } catch (RuntimeException e) {
        LOG.error("Server Error occurred in ExampleServlet", e);
        throw new ServletException(e);
        }
  }
```
---
## `/resources/edmx/csn.json`


## The CDS Complier Version 2.3.0
### Added
- SQL names can now be configured with `{ data: {sql_mapping: "plain/quoted"} }`.  Default is `quoted`, but will be changed to `plain` soon.  If you need to stay with `quoted` in the futute, e.g. due to data compatibility reasons, you can configure this mode already now.

### Fixes
- The `csn.json` file produced by `cds build` now contains the properly unfolded model for OData.  Previously this was the normalized model, which led to runtime errors in the Java service provider.
- Invalid configuration data in `package.json` now leads to a build error again.
- Console output of `cds build` now presents files paths sorted.

### Also see
- Changes of CDS compiler 1.0.27