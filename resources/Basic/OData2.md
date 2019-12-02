# OData协议详解, restfull对OData的GET/PUT/POST/DELET

 OData定义了对不同格式数据的CRUD操作选项, 这些选项基于WEB来实现, 可以通过http请求方式操作.每个功能选项都有一个请求体(包括请求头和请求报文体), 具体请求参数细节都不同, 当选项被响应完成后就向客户端返回xml/json/atom不同格式的响应体(默认返回的是xml格式, 如需要返回其他格式就在url后加$format=xml/json/atom 的参数).下面我们来一一做详细的介绍:

--- 
1. 首先是OData的实体数据模型Entity Data Modle(EDM), 在上篇日志我们已经定义了一个实体Department, 那它对应的EDM都长啥样呢?在地址栏中输入:http://localhost:8080/odata2-jpa2/SemServiceServlet.svc/$metadata  结果如图:

```
<edmx:Edmx xmlns:edmx="http://schemas.microsoft.com/ado/2007/06/edmx" Version="1.0">
<edmx:DataServices xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" m:DataServiceVersion="1.0">
<Schema xmlns="http://schemas.microsoft.com/ado/2008/09/edm" Namespace="odata2_jpa2">
<EntityType Name="Department">
<Key>
<PropertyRef Name="Id"/>
</Key>
<Property Name="Id" Type="Edm.Int32" Nullable="false"/>
<Property Name="Name" Type="Edm.String"/>
</EntityType>
<EntityContainer Name="odata2_jpa2Container" m:IsDefaultEntityContainer="true">
<EntitySet Name="Departments" EntityType="odata2_jpa2.Department"/>
</EntityContainer>
</Schema>
</edmx:DataServices>
</edmx:Edmx>
```

在EDM中我们可以拿到所有的实体信息与其实体属性和类型:
```
<EntitySet Name="Departments" EntityType="odata2_jpa2.Department"/> 
```
在Olingo client 中每次选项请求都要带上一个edm作为参数。

---
2. OData中的GET选项就是查询功能, 将数据暴露出来.在Olingo java库中实现方式是使用CXF将OData的响应结果发布成一个WebService的方式暴露出来.该功能是OData选项最复杂选项, 支持某张表的id查询/某些字段匹配查询/所有记录查询/top/分页查询
---
实际上OData就是定义了资源请求规范, 数据返回规范罢了, 具体实现每种语言都可以去实现, java库就是由Olingo serve来实现, 将CRUD都封装在起来, 响应OData定义的每个选项的请求规范, 按照OData定义的response规范去发布webService, 整个后台代码我们需要做的就是手动数据建模(其实这样也还是有麻烦的, 如果数据库中有几百张表, 那么我们也就要建模几百次了, 貌似现在微软也在提出自动建模的概念, 只要获取到数据库中的表信息就能在后台自动建模, 要实现估计得还一段时间, 每种数据库的实现方式都不同).
       OData让我们减少了很多代码, 但也还是有它自己笨的地方, 比如在DELETE选项中我们只能删除某条记录, 不能同时删除多条或者删除整个表中的记录, 如果要实现只能自定义代码去实现了, 或者循环执行多次DELETE请求(汗吧!).

       再次OData的请求头和请求body很麻烦, 每次做POST或者PUT操作都要拼接复杂的body, 一旦格式稍有不对请求都会失败.不过Olingo已经考虑到了这个问题, 

