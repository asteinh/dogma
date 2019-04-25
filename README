# dogma

Automated API documentation generation for Matlab packages.

## What is dogma?
Dogma stands for **do**cumentation **g**eneration for **Ma**tlab packages and is
a small Matlab package that is supposed to parse another Matlab package (called
*target*). It creates a graph and allows to export the collected information of
the target (contained in the graph representation) in an API documentation
format to LaTeX or HTML.

## Get started
Clone this repository, add it to your Matlab path and run dogma on a Matlab
package of your choice:
```Matlab
import dogma.*;

mypkg = dogma('+yourPackage');
mypkg.buildTree();
mypkg.export('xml','mypkg.xml');
```
For details on the syntax and some basic settings have a look at the
[test script](https://github.com/asteinh/dogma/blob/master/test/test.m).

## Status
Dogma is in development status - while basic functionality is implemented, some
features are missing. Comments, use cases and contributions are very welcome!

## Examples
- #### [RoFaLT](https://gitlab.mech.kuleuven.be/meco-software/rofalt)
  Uses dogma to automatically generate its API documentation in HTML, which is
  [published online](https://meco-software.pages.mech.kuleuven.be/rofalt/docs/rofalt/).
