 OData是Open Data 的缩写(odata)是一个协议,定义的是程序数据库格式标准化的开源数据协议.
该协议定义了可以操作的资源和方法,以及可以对这些资源执行的操作（GET、PUT、POST、MERGE 和 DELETE,分别对应着读取、更新、创建、合并和删除）选项.目前java的实现已经稳定支持到V2版本,由Apache基金会的 Olingo项目组开发实现,该项目是由IBM贡献出来的.更多了解OData V2.0协议:http://www.odata.org/documentation/odata-version-2-0 
       
       Olingo有服务端(实现OData协议)和客户端(封装OData服务 CRUD的application/atom+xml格式请求头+请求报文体).
       下面我们开始搭建一个OData实例, 其中我们使用EclipseLink的JPA实现来与数据库交互(后续还会与hibernate进行整合,hibernate2.3.2版本后就开始支持Olingo).
    
      一:首先创建一个mavn工程, 在pom.xml文件中添加以下依赖(直接复制使用就可以创建所有的依赖,so easy!):
    
 
```<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>my-odata2-jpa2</groupId>
    <artifactId>my-odata2-jpa2</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>war</packaging>
    <!-- Dependency version and encode message -->
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <!-- Plugin Versions -->
        <version.compiler-plugin>2.3.2</version.compiler-plugin>
        <version.deploy-plugin>2.8.1</version.deploy-plugin>
        <version.eclipse-plugin>2.9</version.eclipse-plugin>
        <version.jetty-plugin>8.1.14.v20131031</version.jetty-plugin>
        <!-- Dependency Versions -->
        <version.cxf>2.7.6</version.cxf>
        <version.servlet-api>2.5</version.servlet-api>
        <version.jaxrs-api>2.0-m10</version.jaxrs-api>
        <version.slf4j>1.7.1</version.slf4j>
        <version.olingo>2.0.0</version.olingo>
        <version.olingo-jpa-api>2.0.0</version.olingo-jpa-api>
        <version.olingo-jpa-core>2.0.0</version.olingo-jpa-core>
        <version.olingo-jpa-ref>2.0.0</version.olingo-jpa-ref>
        <version.javax-persistence>2.1.0</version.javax-persistence>
        <version.eclipselink>2.5.2</version.eclipselink>
    </properties>
    <build>
        <!-- Build message -->
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.1</version>
                <configuration>
                    <source>1.6</source>
                    <target>1.6</target>
                </configuration>
            </plugin>
            <plugin>
                <artifactId>maven-war-plugin</artifactId>
                <version>2.3</version>
                <configuration>
                    <warSourceDirectory>WebContent</warSourceDirectory>
                    <failOnMissingWebXml>false</failOnMissingWebXml>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-deploy-plugin</artifactId>
                <version>${version.deploy-plugin}</version>
                <configuration>
                    <skip>true</skip>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-eclipse-plugin</artifactId>
                <version>${version.eclipse-plugin}</version>
                <configuration>
                    <addGroupIdToProjectName>true</addGroupIdToProjectName>
                    <addVersionToProjectName>true</addVersionToProjectName>
                    <wtpversion>2.0</wtpversion>
                    <downloadSources>true</downloadSources>
                    <downloadJavadocs>true</downloadJavadocs>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.mortbay.jetty</groupId>
                <artifactId>jetty-maven-plugin</artifactId>
                <version>${version.jetty-plugin}</version>
            </plugin>
        </plugins>
    </build>
    <!-- plugins dependency -->
    <dependencies>
        <!-- Apache Olingo Library dependencies -->
        <dependency>
            <groupId>org.apache.olingo</groupId>
            <artifactId>olingo-odata2-api</artifactId>
            <version>${version.olingo}</version>
        </dependency>
        <dependency>
            <artifactId>olingo-odata2-api-annotation</artifactId>
            <groupId>org.apache.olingo</groupId>
            <type>jar</type>
            <version>${version.olingo}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.olingo</groupId>
            <artifactId>olingo-odata2-core</artifactId>
            <version>${version.olingo}</version>
        </dependency>
        <!-- Additional dependencies -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
            <version>${version.slf4j}</version>
        </dependency>
        <!-- Servlet/REST dependencies -->
        <dependency>
            <!-- required because of auto detection of web facet 2.5 -->
            <groupId>javax.servlet</groupId>
            <artifactId>servlet-api</artifactId>
            <version>${version.servlet-api}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>javax.ws.rs</groupId>
            <artifactId>javax.ws.rs-api</artifactId>
            <version>${version.jaxrs-api}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.cxf</groupId>
            <artifactId>cxf-rt-frontend-jaxrs</artifactId>
            <version>${version.cxf}</version>
        </dependency>
        <!-- jpa dependency  -->
        <dependency>
            <groupId>org.apache.olingo</groupId>
            <artifactId>olingo-odata2-jpa-processor-api</artifactId>
            <version>${version.olingo-jpa-api}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.olingo</groupId>
            <artifactId>olingo-odata2-jpa-processor-core</artifactId>
            <version>${version.olingo-jpa-core}</version>
        </dependency>
        <dependency>
           <groupId>org.apache.olingo</groupId>
           <artifactId>olingo-odata2-jpa-processor-ref</artifactId>
           <version>${version.olingo-jpa-ref}</version>
         </dependency>
        <dependency>
            <groupId>org.eclipse.persistence</groupId>
            <artifactId>eclipselink</artifactId>
            <version>${version.eclipselink}</version>
        </dependency>
        <dependency>
            <groupId>org.eclipse.persistence</groupId>
            <artifactId>javax.persistence</artifactId>
            <version>${version.javax-persistence}</version>
        </dependency>
        
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```
 
* 二:编写一个SemOdataJPAServiceFactory.java类实现ODataJPAServiceFactory接口,复写ODataJPAContext  initializeODataJPAContext(){}方法 如:
 
```package core;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;
import org.apache.olingo.odata2.jpa.processor.api.ODataJPAContext;
import org.apache.olingo.odata2.jpa.processor.api.ODataJPAServiceFactory; 
import org.apache.olingo.odata2.jpa.processor.api.exception.ODataJPARuntimeException;
/**
 * 
 * Title: MVNO-CRM <br>
 * Description: <br>
 * Date: 2014年10月11日 <br>
 * Copyright (c) 2014 Microsoft <br>
 * 
 * @author Li Ming Ding
 */
public  class SemOdataJPAServiceFactory extends ODataJPAServiceFactory {
    private static final String persistenceUnitName = "odata2_jpa2";
    @Override
    public ODataJPAContext initializeODataJPAContext()
            throws ODataJPARuntimeException {
          ODataJPAContext oDataJPAContext = this.getODataJPAContext();  
            try {  
                EntityManagerFactory emf = Persistence  
                        .createEntityManagerFactory(persistenceUnitName);  
                oDataJPAContext.setEntityManagerFactory(emf);  
                oDataJPAContext.setPersistenceUnitName(persistenceUnitName);  
                return oDataJPAContext;  
            } catch (Exception e) {  
                System.out.println(e.getMessage());
            }  
    }
}```
 
* 三:在web.xml中配置核心控制器org.apache.cxf.jaxrs.servlet.CXFNonSpringJaxrsServlet,其中我们要注入两个参数,javax.ws.rs.Application=org.apache.olingo.odata2.core.rest.app.ODataApplication 和 org.apache.olingo.odata2.service.factory=core.SemOdataJPAServiceFactory(SemOdataJPAServiceFactory就是上面我们自定义的factory)  如:
 
```<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="http://java.sun.com/xml/ns/javaee"
    xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
    id="WebApp_ID" version="3.0">
<display-name>org.apache.olingo.odata2.sample</display-name>
  <servlet>
    <servlet-name>SemServiceServlet</servlet-name>
    <servlet-class>org.apache.cxf.jaxrs.servlet.CXFNonSpringJaxrsServlet</servlet-class>
    <init-param>
      <param-name>javax.ws.rs.Application</param-name>
      <param-value>org.apache.olingo.odata2.core.rest.app.ODataApplication</param-value>
    </init-param>
    <init-param>
      <param-name>org.apache.olingo.odata2.service.factory</param-name>
      <param-value>core.SemOdataJPAServiceFactory</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
  </servlet>
  <servlet-mapping>
    <servlet-name>SemServiceServlet</servlet-name>
    <url-pattern>/SemServiceServlet.svc/*</url-pattern>
  </servlet-mapping>
  
    <welcome-file-list>
    <welcome-file>index.jsp</welcome-file>
  </welcome-file-list>
</web-app>```
 
 * 四: 现在我们最后来配置Persistence的核心配置文件了(这里是最头痛的地方!),persistence.xml必须放在META-INF文件根目录下(这里的META-INF不是我们平时和WEB-INF同级的目录哦!),而是resources文件根目录下的META-INF  如:


 persistence.xml 文件内容: 定义unitName="odata2_jpa2",定义核心provader,配置我们定义的实体类,最后就是配置数据库的数据源了 如:
 
``` <?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.0"
    xmlns="http://java.sun.com/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd">
    <persistence-unit name="odata2_jpa2"
        transaction-type="RESOURCE_LOCAL">
        <provider>org.eclipse.persistence.jpa.PersistenceProvider</provider>  
        <class>entity.Persion</class>
        <class>entity.Employee</class>
        <class>entity.Department</class>
        <properties>  
            <property name="javax.persistence.jdbc.url" value="jdbc:mysql://127.0.0.1:3306/test" />  
            <property name="javax.persistence.jdbc.driver" value="com.mysql.jdbc.Driver" />  
            <property name="javax.persistence.jdbc.user" value="root" />  
            <property name="javax.persistence.jdbc.password" value="sorry" />  
        </properties> 
    </persistence-unit>
</persistence>
 
 五:最后我们要做的就是编写数据实体对象了,其实很简单,跟我们使用hibernate映射数据差不多的.
      Department.java  代码如下:
 
```package entity;
import javax.persistence.Basic;
import javax.persistence.Entity;
import javax.persistence.Id;
@Entity
public class Department {
    @Id
    private int id;
    @Basic
    private String name;
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    
}
 @Entity就是描述该类是一个实体类,@Id是描述该属性为主键id,@Basic是描述该属性为普通属性,属性类型和数据库字段的类型一致,否则映射失败. 其他的实体映射同理.

六:将项目部署到tomcat上测试. 
    1,在mysql数据库中表department中准备三条数据:
    
    2,查询(GET),单单查询我们可以使用浏览器就能完成测试:在url中输入:http://127.0.0.1:8080/odata2-jpa2/SemServiceServlet.svc/Departments   如图:

     

我们已经成功使用JPA将数据库转换成OData协议的service发布了. 下面我们就可以直接使用RestFull来访问数据库中的资源.

个人使用感觉:OData很通用,任何语言都可以实现,将传统的后台MVC都封装成立Service,还支持扩展应用,这种框架架构理念很酷,实际开发应用方便了很多,我们省去了action controllor service dao 代码的繁琐和bug调试,但是OData也有自己的缺点:就是没法像jdbc那样灵活操作数据库,普通的CRUD是没有问题的,但是复杂的就不行了.对于OData,如果你主要是做数据开源而没有太复杂业务逻辑的话,那它就是最好的选择了.
