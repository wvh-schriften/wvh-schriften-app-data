
xquery version "3.1";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-wvh-schriften-web="http://www.tei-c.org/pm/models/wvh-schriften/web/module" at "../transform/wvh-schriften-web-module.xql";
import module namespace pm-wvh-schriften-print="http://www.tei-c.org/pm/models/wvh-schriften/print/module" at "../transform/wvh-schriften-print-module.xql";
import module namespace pm-wvh-schriften-latex="http://www.tei-c.org/pm/models/wvh-schriften/latex/module" at "../transform/wvh-schriften-latex-module.xql";
import module namespace pm-wvh-schriften-epub="http://www.tei-c.org/pm/models/wvh-schriften/epub/module" at "../transform/wvh-schriften-epub-module.xql";
import module namespace pm-wvh-schriften-fo="http://www.tei-c.org/pm/models/wvh-schriften/fo/module" at "../transform/wvh-schriften-fo-module.xql";
import module namespace pm-docx-tei="http://www.tei-c.org/pm/models/docx/tei/module" at "../transform/docx-tei-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "wvh-schriften.odd" return pm-wvh-schriften-web:transform($xml, $parameters)
    default return pm-wvh-schriften-web:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:print-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "wvh-schriften.odd" return pm-wvh-schriften-print:transform($xml, $parameters)
    default return pm-wvh-schriften-print:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:latex-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "wvh-schriften.odd" return pm-wvh-schriften-latex:transform($xml, $parameters)
    default return pm-wvh-schriften-latex:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:epub-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "wvh-schriften.odd" return pm-wvh-schriften-epub:transform($xml, $parameters)
    default return pm-wvh-schriften-epub:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:fo-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "wvh-schriften.odd" return pm-wvh-schriften-fo:transform($xml, $parameters)
    default return pm-wvh-schriften-fo:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:tei-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx.odd" return pm-docx-tei:transform($xml, $parameters)
    default return error(QName("http://www.tei-c.org/tei-simple/pm-config", "error"), "No default ODD found for output mode tei")
            
    
};
            
    