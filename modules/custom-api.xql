xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace api="http://teipublisher.com/api/custom";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";


(: Add your own module imports here :)
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace app="teipublisher.com/app" at "app.xql";


(:~
 : Keep this. This function does the actual lookup in the imported modules.
 :)
declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function api:table-of-contents($request as map(*)) { 
  let $docs := collection($config:data-default)/tei:TEI
  let $volumes := distinct-values(for $doc in $docs return number(tokenize($doc//tei:pb[1]/@n, "\.")[1]))

  return 
  <ul>
  {
    for $volume in $volumes
    order by $volume ascending
    return
      let $docList :=
        for $doc in $docs
        let $pbNums := $doc//tei:pb[starts-with(@n, concat($volume, "."))]/@n
        where exists($pbNums)
        let $minPageNum := min(for $n in $pbNums return number(tokenize($n, "\.")[2]))
        order by $minPageNum ascending
        return $doc

      let $content :=
        for $pos in $docList
        let $relPath := substring-after(document-uri(root($pos)), $config:data-default || "/")
        let $title := normalize-space(string($pos//tei:titleStmt/tei:title[1]))
        let $pages := $pos//tei:pb[number(tokenize(@n, "\.")[1]) = $volume]
        let $sortedPages :=
          for $p in $pages
          let $pageNum := number(tokenize(string($p/@n), "\.")[2])
          order by $pageNum ascending
          return $p
        where exists($sortedPages)
        return (
          <li>
            <pb-collapse>
              <span slot="collapse-trigger">{ $title }</span>
              <span slot="collapse-content">
                <ul>
                {
                  for $page in $sortedPages
                  let $pageNum := tokenize(string($page/@n), '\.')[2]
                  let $pageId := string($page/@xml:id)
                  return
                    <li>
                      <a href="{ $relPath }#{$pageId}">§{ $pageNum }</a>
                    </li>
                }
                </ul>
              </span>
            </pb-collapse>
          </li>
        )
      return
        if (exists($content)) then
          <li>
            <pb-collapse>
              <span slot="collapse-trigger"><strong>Band { $volume }</strong></span>
              <span slot="collapse-content">
                <ul>{ $content }</ul>
              </span>
            </pb-collapse>
          </li>
        else ()
  }
  </ul>
};

declare function api:timeline($request as map(*)) {
  let $sessionPrefix := "wvh-schriften"
  let $entries := session:get-attribute(concat($sessionPrefix, ".hits"))

  let $datedEntries :=
    for $entry in $entries
    let $doc := doc(base-uri($entry))
    let $dateStr := $doc//tei:profileDesc/tei:creation/tei:date/@when/string()
    let $fullDateStr := if (matches($dateStr, "^\d{4}$")) then concat($dateStr, "-01-01") else $dateStr
    let $date := if ($fullDateStr and matches($fullDateStr, "^\d{4}-\d{2}-\d{2}")) then xs:date($fullDateStr) else ()
    where exists($date) and year-from-date($date) ne 1000
    let $xmlId := string($doc/tei:TEI/@xml:id)
    let $title := string(($doc//tei:titleStmt/tei:title)[1])
    return map { "id": $xmlId, "date": $date, "title": $title }

  let $grouped :=
    for $d in distinct-values(for $e in $datedEntries return $e("date"))
    let $docs := for $e in $datedEntries where $e("date") = $d return $e
    let $count := count($docs)
    let $info := array {
      for $doc in subsequence($docs, 1, 5)
      return
        concat('<a href="', $config:context-path, '/document/', $doc("id"), '" part="tooltip-link">', $doc("title"), '</a>')
    }
    order by $d
    return map:entry(format-date($d, "[Y0001]-[M01]-[D01]"), map { "count": $count, "info": $info })

  return map:merge($grouped)
};


declare function api:people($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category
    let $view := $request?parameters?view
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $people := 
        if ($search and $search != '') then
            doc("/db/apps/wvh-schriften/resources/registers/person.xml")//tei:listPerson/tei:person[
                contains(lower-case(string(tei:persName[@type='main'])), lower-case($search))
            ]
        else
            doc("/db/apps/wvh-schriften/resources/registers/person.xml")//tei:listPerson/tei:person

    let $byKey := for-each($people, function($person as element()) {
        let $label := string($person/tei:persName[@type='main'])
        let $sortKey := 
            if (starts-with($label, "von ")) then substring($label, 5)
            else $label
        return [lower-case($sortKey), $label, $person]
    })

    let $sorted := api:sort($byKey, $sortDir)
    let $letter := 
        if (count($people) < $limit) then
            "Alle"
        else if ($letterParam = '') then
            substring($sorted[1]?1, 1, 1) => upper-case()
        else
            $letterParam

    let $byLetter := 
        if ($letter = 'Alle') then $sorted
        else filter($sorted, function($entry) {
            starts-with($entry?1, lower-case($letter))
        })

    return map {
        "items": api:output-person($byLetter, $letter, $view, $search),
        "categories": 
            if (count($people) < $limit) then
                []
            else array {
                for $index in 1 to string-length('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
                let $alpha := substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ', $index, 1)
                let $hits := count(filter($sorted, function($entry) { starts-with($entry?1, lower-case($alpha)) }))
                where $hits > 0
                return map { "category": $alpha, "count": $hits },
                map { "category": "Alle", "count": count($sorted) }
            }
    }
};

declare function api:output-person($list, $letter as xs:string, $view as xs:string, $search as xs:string?) {
    array {
        for $person in $list
        let $letterParam := if ($letter = "Alle") then substring($person?3/@xml:id, 1, 1) else $letter
        return
            <span>
                <a href="{$person?2}?key={$person?3/@xml:id}">{$person?2}</a>
            </span>
    }
};

declare function api:sort($people as array(*)*, $dir as xs:string) {
    let $sorted :=
        sort($people, "?lang=de-DE", function($entry) {
            $entry?1
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};


declare function api:places($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category
    let $view := $request?parameters?view
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit

    let $places :=
        if ($search and $search != '') then
            doc("/db/apps/wvh-schriften/resources/registers/places.xml")//tei:listPlace/tei:place[
                contains(lower-case(string(tei:placeName[@type='main'])), lower-case($search))
                or contains(lower-case(string(tei:placeName[@type='sort'])), lower-case($search))
            ]
        else
            doc("/db/apps/wvh-schriften/resources/registers/places.xml")//tei:listPlace/tei:place

    let $byKey := for-each($places, function($place as element()) {
        let $label := 
            if ($place/tei:placeName[@type='sort']) 
            then string($place/tei:placeName[@type='sort'])
            else string($place/tei:placeName[@type='main'])
        let $sortKey :=
            if (starts-with($label, "von ")) then substring($label, 5)
            else $label
        return [lower-case($sortKey), $label, $place]
    })

    let $sorted := api:sort($byKey, $sortDir)
    let $letter :=
        if (count($places) < $limit) then
            "Alle"
        else if ($letterParam = '') then
            substring($sorted[1]?1, 1, 1) => upper-case()
        else
            $letterParam

    let $byLetter :=
        if ($letter = 'Alle') then $sorted
        else filter($sorted, function($entry) {
            starts-with($entry?1, lower-case($letter))
        })

    return map {
        "items": api:output-place($byLetter, $letter, $view, $search),
        "categories":
            if (count($places) < $limit) then
                []
            else array {
                for $index in 1 to string-length('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
                let $alpha := substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ', $index, 1)
                let $hits := count(filter($sorted, function($entry) { starts-with($entry?1, lower-case($alpha)) }))
                where $hits > 0
                return map { "category": $alpha, "count": $hits },
                map { "category": "Alle", "count": count($sorted) }
            }
    }
};

declare function api:output-place($list, $letter as xs:string, $view as xs:string, $search as xs:string?) {
    array {
        for $place in $list
        let $notes := $place?3/tei:note
        let $letterParam := if ($letter = "Alle") then substring($place?3/@xml:id, 1, 1) else $letter
        return
            <span>
                <a href="{$place?2}?key={$place?3/@xml:id}">{$place?2}</a>
            </span>
    }
};

