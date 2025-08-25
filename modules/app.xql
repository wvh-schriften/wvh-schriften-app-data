xquery version "3.1";

(:
 : Module for app-specific template functions
 :
 : Add your own templating functions here, e.g. if you want to extend the template used for showing
 : the browsing view.
 :)
module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %templates:wrap
function app:foo($node as node(), $model as map(*)) {
    <p>Dummy templating function.</p>
};

declare %templates:wrap
        %templates:default("type", "person")
function app:load-person($node as node(), $model as map(*), $id as xs:string?) {

  let $key := if (empty($id)) then request:get-parameter("key", "") else $id

  return
    if (empty($key)) then
      <div><p>No ID provided.</p></div>
    else
      let $uri := '/db/apps/wvh-schriften/resources/registers/person.xml'
      let $doc := doc($uri)
      let $person := $doc//tei:person[@xml:id = $key]

      (: helper function to format date "YYYY-MM-DD" to "DD-MM-YYYY" :)
      let $format-date := function($date as xs:string) as xs:string {
        if (empty($date)) then ""
        else
          let $parts := tokenize($date, "-")
          return
            concat(
                  substring($parts[3],1,2), "-",  
                  substring($parts[2],1,2), "-", 
                  $parts[1]                     
                )
      }

      let $birth-date := $format-date(string($person/tei:birth/tei:date/@when))
      let $birth-place := normalize-space(string($person/tei:birth/tei:placeName))
      let $death-date := $format-date(string($person/tei:death/tei:date/@when))
      let $death-place := normalize-space(string($person/tei:death/tei:placeName))

      return
        <div class="person-info">
          <h1>{ normalize-space($person/tei:persName[@type='main']) }</h1>

          <p><strong>Gender:</strong>&#160;{ normalize-space($person/tei:gender) }</p>

          <p><strong>Birth:</strong>&#160;{ $birth-date }
            { if ($birth-place) then concat(", ", $birth-place) else () }
          </p>

          <p><strong>Death:</strong>&#160;{ $death-date }
            { if ($death-place) then concat(", ", $death-place) else () }
          </p>

          <p><strong>Occupation:</strong>&#160;{
            string-join(
              for $o in $person/tei:occupation
              return normalize-space(string($o)),
            ", ")
          }</p>

          <p><strong>Bio:</strong>&#160;{ normalize-space($person/tei:note[@type='bio']) }</p>
        </div>
};



declare %templates:wrap
        %templates:default("type", "person")
function app:person-mentions($node as node(), $model as map(*), $type as xs:string) {
  let $key := request:get-parameter("key", "")
  let $log := util:log("info", "app:person-mentions (alt): using request key = " || $key)

  let $matches := collection("/db/apps/wvh-schriften/data")//tei:TEI[.//tei:persName[@ref = $key]]

  return
    <div>
      <h2>Erwähnt:</h2>
      {
        if (count($matches) > 0) then
          <ul>{
            for $doc in $matches
            let $mention-count := count($doc//tei:persName[@ref = $key])
            order by $mention-count descending, util:document-name($doc) ascending
            let $doc-name := util:document-name($doc)
            let $title := $doc//tei:titleStmt/tei:title/string()
            return
              <li>
                <a href="/exist/apps/wvh-schriften/{$doc-name}">{$title}</a>
                <span> ({$mention-count} Mal)</span>
              </li>
          }</ul>
        else
          <p>No results for key: <code>{$key}</code></p>
      }
    </div>
};





declare %templates:wrap 
function app:count-letters($node as node(), $model as map(*)) {
    count(collection($config:data-root)//tei:TEI[exists(.//tei:publisher)])
};
declare %templates:wrap 
function app:count-people($node as node(), $model as map(*)) {
    count(doc($config:data-root || "/person.xml")//tei:person[exists(.//tei:surname)])
};

declare %templates:wrap
        %templates:default("type", "place")
function app:load-place($node as node(), $model as map(*), $id as xs:string?) {

  let $key := if (empty($id)) then request:get-parameter("key", "") else $id

  return
    if (empty($key)) then
      <div><p>No ID provided.</p></div>
    else
      let $uri := '/db/apps/wvh-schriften/resources/registers/places.xml'
      let $doc := doc($uri)
      let $place := $doc//tei:place[@xml:id = $key]

      let $name := normalize-space($place/tei:placeName[@type='main'])
      let $country := normalize-space($place/tei:country)
      let $region := normalize-space($place/tei:region)
      let $note := normalize-space(string-join($place/tei:note//text(), " "))

      return
        <div class="place-info">
          <h1>{$name}</h1>
          { if ($country) then <p><strong>Country:</strong>&#160;{$country}</p> else () }
          { if ($region) then <p><strong>Region:</strong>&#160;{$region}</p> else () }
          { if ($note) then <p><strong>Note:</strong>&#160;{$note}</p> else () }
        </div>
};

declare %templates:wrap
        %templates:default("type", "place")
function app:place-mentions($node as node(), $model as map(*), $type as xs:string) {
  let $key := request:get-parameter("key", "")
  let $log := util:log("info", "app:person-mentions (alt): using request key = " || $key)

  let $matches := collection("/db/apps/wvh-schriften/data")//tei:TEI[.//tei:placeName[@ref = $key]]

  return
    <div>
      <h2>Erwähnt:</h2>
      {
        if (count($matches) > 0) then
          <ul>{
            for $doc in $matches
            let $mention-count := count($doc//tei:placeName[@ref = $key])
            order by $mention-count descending, util:document-name($doc) ascending
            let $doc-name := util:document-name($doc)
            let $title := $doc//tei:titleStmt/tei:title/string()
            return
              <li>
                <a href="/exist/apps/wvh-schriften/{$doc-name}">{$title}</a>
                <span> ({$mention-count} Mal)</span>
              </li>
          }</ul>
        else
          <p>No results for key: <code>{$key}</code></p>
      }
    </div>
};

