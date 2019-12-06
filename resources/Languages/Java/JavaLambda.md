# Java中的函数式编程

## 出现的原因
语言面临着要么改变,要么衰亡的压力. Java是传统的命令式编程,而函数式编程.是一种更"高级"的编程范式,Java为了支持它,推出了Lambda表达式和Stream.

---

## 函数式编程 VS 命令式编程
一言以蔽之, 函数式编程是:
* "我现在想要这样东西(怎么办到我不管,你来处理)"

命令式编程是:
* "你要先...,再...,最后...,就能拿到这样东西了"

事实上,函数式编程的底层实现还是命令式编程,就像面向对象语言核心部分(如JVM)是由面向过程语言(如C)实现的.毕竟脏活累活总是要有人去做的.

---

## 举个栗子
以一个比较苹果重量的Comparator为例,类Apple定义如下
```java
public class Apple{
    private int weight;
    private int type;
    public int getWeight(){
        return this.weight;
    }
    public int getType(){
        return this.type;
    }
}
```

如果按照匿名类实现,代码会是这样,总体来说比较繁琐.
```java
Comparator<Apple> byWeight=new Comparator<>(){
    @Override
    public int compareTo(Apple a1,Apple a2) {
        return a1.getWeight().compareTo(a2.getWeight());
    }
}
```

如果使用Lambda表达式,最繁琐的形式会是这样
```java
Comparator<Apple> byWeight=
(Apple a1,Apple a2) -> {return a1.getWeight().compareTo(a2.getWeight());}
```
要搞清楚Lambda表达式的工作原理,首先要了解它的语法以及函数式接口

---

## Lambda表示式 VS 方法

Lambda的语法结构如下
```java
// 参数列表 箭头 方法体
( ParameterType1 param1,ParameterType2 param2... ) -> { ... } 
```

方法的语法结构如下(暂不考虑throws)
```
访问权限 ReturnType methodName(ParameterType1 param1,ParameterType2 param2...){
    ... 
}
```

可以看出,Lambda表达式可以看做方法的简化形式: 没有访问权限,返回类型以及方法名.并且它还可以进一步简化

---

## 函数式接口
* 有且只有一个抽象方法的接口

首先澄清一下这里抽象方法的定义

1. 接口中的default方法不是抽象方法,因为它有默认实现
2. 如果接口中的方法覆盖了java.lang.Object中的方法,也不做计数

下面以Comparator为例(适当精简)
```java
@FunctionalInterface
public interface Comparator<T> {
    int compare(T o1, T o2);//1
  boolean equals(Object obj);//2
    default Comparator<T> reversed() {//3
        return Collections.reverseOrder(this);
  }
}
```

`@FunctionalInterface`用来标识一个接口是函数式接口,它和`@Override`注解类似,只是编译时起检查作用,如果这个接口定义不符合的话,编译时就会报错,如果一个接口符合函数式接口的定义,即使没有这个注解依然是有效的

再来看下Comparator中有几个抽象方法

1. 是抽象方法
2. 覆盖了Object.equal()方法,所以不是
3. 是default方法,也不是抽象方法

只有一个抽象方法,因此Comparator接口是一个函数式接口.

说了这么多,函数式接口到底有什么作用呢?
* Lambda表达式允许你直接以内联的形式为函数式接口的抽象方法提供实现,`并把整个表达式作为函数式接口的实例`

当我们把一个Lambda表达式赋给一个函数式接口时,这个表达式对应的必定是接口中唯一的抽象方法,因此就不需要以匿名类那么繁琐的形式去实现这个接口.可以说在语法简化上,Lambda表达式完成了方法层面的简化,函数式接口完成了类层面的简化.

---

## Lambda表达式的进一步简化
在Lambda中,除了参数列表的大括号()和箭头→不能省略,其他部分如果编译器可以自动推断,都能省略.

* 简化规则1: 如果编译器可以推断出参数类型,参数列表中就可以省略参数类型
```java
Comparator<Apple> byWeight=
(a1,a2) -> {return a1.getWeight().compareTo(a2.getWeight());}
```

* 简化规则2: 如果方法体只有一条语句,花括号{}和return(如果有的话)都可以省略
```java
Comparator<Apple> byWeight=
(a1,a2) ->  a1.getWeight().compareTo(a2.getWeight())
```

* 简化规则3: 可以通过方法引用来调用方法

首先要介绍一个新概念:方法引用,它的基本思想是:如果一个Lambda代表的只是直接调用这个方法,那最好还是用名称来调用它,而不是去描述如何调用它. 这样可读性更好.

方法引用的一般形式如下
```java
//可以表示对静态/实例方法的调用
类名::方法名
//只能表示实例方法
this::方法名
```

针对上面的例子,首先利用JDK提供的工具做一些简化
```java
Comparator<Apple> byWeight=
Comparator.comparingInt((a)->a.getWeight())
```

然后利用方法引用可以简化为如下形式,是不是简单明了?
```java
Comparator<Apple> byWeight= Comparator.comparingInt(Apple::getWeight)
```
然而Lambda并不是万金油,它也有自己的限制.

---

## Lambda的局部变量限制

Lambda引用局部变量时,要求局部变量时final或effective final(即仅被赋值一次,之后不被修改).实例变量则可以随意使用.这个限制有如下几个原因

* 堆和栈的差异

    局部变量是存储在栈上的,即局部变量是线程私有的,而Lambda表达式不是线程私有的,它可能在其他线程上执行,而其他线程上是没有对应的局部变量的(实例变量是在堆上分配的,任何线程都能访问到),为了解决这个问题,Java会将局部变量的拷贝一份保存到在Lambda表达式中.因此Java在访问局部变量时,实际是在访问它的副本,而不是访问原始变量. 如果局部变量不是effective final的(比如在Lambda表达式之后对原始变量进行了修改),拷贝就可能和原始变量不一致,会引发很多语义上的问题(匿名内部类中局部变量也是相同原因)

* 避免函数式编程的不正确使用

    局部变量必须是effective final恰好符合函数式编程的特征之一—immutable data 数据不可变.数据不可变便没有了数据竞争问题,这样最有利于并行

    假设非effective final局部变量是被允许的,那么下面这句代码实际上是串行执行的,因为每个任务都在竞争sum这个变量

    ```java
    int sum=0;
    //parallelStream()会以多线程形式执行任务
    ints.parallelStream().forEach(i->sum+=i);
    ```
---

## 又一个例子

需求: 有一堆苹果List<Apple> apples,以重量从小到大,获取他们的品种.

以命令式编程来做会是:

```java
Comparator<Apple> byWeight=new Comparator<>(){
    @Override
    public int compareTo(Apple a1,Apple a2) {
        return a1.getWeight().compareTo(a2.getWeight());
    }
}
apples.sort(byWeight);
List<Integer> types=new ArrayList();
for(Apple apple:apples){
    types.add(apple.getType());
}
```

有了Stream,会是这样,语义清晰了很多,个人非常喜欢这种链式调用(链式调用一时爽,一直链式一直爽)再次展示出命令式编程和函数式编程的不同
```java
List<Integer> types = apples
                    .stream()
                    .sorted(Comparator.comparingInt(Apple::getWeight))
                    .map(Apple::getType)
                    .collect(Collectors.toList()); 
```

在日常开发中,将一个列表进行排序过滤转化最后收集这个套路十分常见,这个过程中变化的只是我们传递过去的Lambda表达式，这也被称为行为参数化

* 行为参数化

    一个方法接受多个不同的行为作为参数,并在内部使用它们,完成不同行为.

* 参数化

    Apple::getType这个行为 是作为一个参数传递给map()的,这就是参数化

---

## parallelStream—并行化任务的最简单方式

假设现在有一个包含100w元素的List,要对它进行一系列操作,元素很多,会消耗很多时间.

```java
elements.stream().filter(...).map(...).collect(...);
```

很明显,多线程执行能够加速执行,只需要一点点修改就能使它以多线程模式执行,wonderful!

```java
elements.parallelStream().filter(...).map(...).collect(...);
```

`parallelStream的底层是fork/join框架.可以把它理解一个智能的线程池,它能将任务拆分并分发给不同的线程执行,最终汇总`.然而 parallelStream并不是银弹,以下几点需要注意

1. parallelStream()的后续操作中进行排序(调用sorted())得出的结果是无效的.原因很简单,它是多线程执行的.这个问题的解决办法就是在parallelStream结束后再进行排序.

2. 执行的任务不能依赖于线程私有数据(比如ThreadLocal),由于是多线程执行,其他线程并没有当前线程栈上的数据,一个最常见的例子就是在spring中执行数据库操作,session是绑定在线程上的,这时候以parallelStream执行就会报错 can't obtain session

3. 任务数量必须足够多/单个任务耗时很长(io/网络操作)才有必要使用parallelStream,不然运行反而会更慢. 因为要fork/join也是要付出很大代价的: 划分子任务,分配任务给线程.具体的计算规则

---

## 使用JDK中新增的Lambda相关方法

又又又是一个例子: 对Map<String,Integer> map中的所有值进行+1操作,在JDK8中,最好的做法如下

```java
map.replaceAll((key,oldVal)->oldVal+1);
```

首先看replaceAll方法的签名,replaceAll接收一个BiFunction作为参数,很明显 这个BiFunction就是我们要传递的行为

```java
/**
     * Replaces each entry's value with the result of invoking the given
     * function on that entry until all entries have been processed or the
     * function throws an exception.  Exceptions thrown by the function are
     * relayed to the caller.
     *
**/
default void replaceAll(BiFunction<? super K, ? super V, ? extends V> function){
    ...
}
```

再来看BiFunction的定义,它是一个函数式接口,apply方法接收两个参数,有返回值

```java
@FunctionalInterface
public interface BiFunction<T, U, R> {

    /**
     * Applies this function to the given arguments.
     *
     * @param t the first function argument
     * @param u the second function argument
     * @return the function result
     */
    R apply(T t, U u);
}
```

再来看我们提供的Lambda表达式,符合Map.replaceAll中对BiFunction.apply的方法签名要求

```java
(key,oldVal)->oldVal+1
```

使用JDK8新增的Lambda相关方法,可以大概遵循下面这个步骤

查找符合需求的api,如replaceAll
查看该方法要求的行为(参数)的定义,如BiFucntion.apply()
编写符合方法签名的Lambda表达式
