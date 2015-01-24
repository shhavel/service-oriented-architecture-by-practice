Preface
=======
## HTTP APIs
In information technologies world everything revolves around... Information. And Web is a very great way to disseminate information. The ability of users to access information metter.

Consider a small example. Suppose that you have a website and you monetize it by advertising on the site pages. More content (or data, or information) you have and the higher quality (the more interesting it is for users) it has - more money you earn. If you site is static (always same amout of same pages) you do not have many choises to increase profits. Thus, you can hire a moderator (or be yourself moderator) and create restricted part on the website where your moderator(s) can create (and edit) new content. Once it starts to work amount of content will increase linearly.

You might want to also increase the speed of building content. And you will decide open access to users (in this case you should think about security, legality - terms of use). If users will be motivated to post new content on your site amount of content will grow exponentially, because more content you have - more users you have, and more users you have - more new content they create.

![](images/content_vs_time.png)

And there is more! Now you can interact with other sites or services to allow users of other services to access your countent. More simple and convenient way you will find - more success you will have. Hard to imagine...

This is not the only area of application HTTP APIs. There are projects that internally constructed of small services that interact with each other throw APIs. That kind of service can be called API itself. And architecture of such project is called Service Oriented Architecture which this book is devoted to.

## RPC vs REST
So if you need to provide access to your application for some other application(s), that can be maintained by some other developers and can be written in any programming languages you probably need some usage agreement or rules (and documentation) that in general is finite list of remote calls (or methods, or procedures) with some specifications.
It is advisable to pick up some well-known or intuitive format. One choice is to use XML-RPC (Remote Procedure Call), it uses XML for encoding messages - method calls and data also in XML format. That XML that sent by HTTP. But HTTP is protocol itself on which REST (Representational State Transfer) completely relies. URL is used to determine resource type or unique resource item and HTTP method such as POST, GET, PUT, DELETE is used to determine method: Create, Read, Update, Delete (this set of atomic methods should be enough to accomplish any action). Compering to REST XML-RPC is like envelope with the data (Top level XML) placed in another envelope (HTTP).
In this book REST convention are followed. REST does not tie you to any or data format. We will use mostly JSON.

## Technologies
In this book we will not compare too much different technologies that can be used for building Web services.
We will focus more on general architecture and use ruby language because it is concise and understandable for people who new to ruby. Also we will use sinatra framework and related ruby gems.
To start read the book you need to have ruby (1.9 or later) and ruby gems to be installed in your system.
