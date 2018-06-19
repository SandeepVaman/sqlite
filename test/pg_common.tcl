# 2018 May 19
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
#

package require sqlite3
package require Pgtcl

set db [pg_connect -conninfo "dbname=postgres user=postgres password=postgres"]
sqlite3 sqlite ""

proc execsql {sql} {

  set lSql [list]
  set frag ""
  while {[string length $sql]>0} {
    set i [string first ";" $sql]
    if {$i>=0} {
      append frag [string range $sql 0 $i]
      set sql [string range $sql $i+1 end]
      if {[sqlite complete $frag]} {
        lappend lSql $frag
        set frag ""
      }
    } else {
      set frag $sql
      set sql ""
    }
  }
  if {$frag != ""} {
    lappend lSql $frag
  }
  #puts $lSql

  set ret ""
  foreach stmt $lSql {
    set res [pg_exec $::db $stmt]
    set err [pg_result $res -error]
    if {$err!=""} { error $err }
    for {set i 0} {$i < [pg_result $res -numTuples]} {incr i} {
      if {$i==0} {
        set ret [pg_result $res -getTuple 0]
      } else {
        append ret "   [pg_result $res -getTuple $i]"
      }
      # lappend ret {*}[pg_result $res -getTuple $i]
    }
    pg_result $res -clear
  }

  set ret
}

proc execsql_test {tn sql} {
  set res [execsql $sql]
  set sql [string map {string_agg group_concat} $sql]
  puts $::fd "do_execsql_test $tn {"
  puts $::fd "  [string trim $sql]"
  puts $::fd "} {$res}"
  puts $::fd ""
}

# Same as [execsql_test], except coerce all results to floating point values
# with two decimal points.
#
proc execsql_float_test {tn sql} {
  set F "%.2f"
  set res [execsql $sql]
  set res2 [list]
  foreach r $res { 
    if {$r != ""} { set r [format $F $r] }
    lappend res2 $r
  }

  puts $::fd "do_test $tn {"
  puts $::fd "  set myres {}"
  puts $::fd "  foreach r \[db eval {[string trim $sql]}\] {"
  puts $::fd "    lappend myres \[format $F \[set r\]\]"
  puts $::fd "  }"
  puts $::fd "  set myres"
  puts $::fd "} {$res2}"
  puts $::fd ""
}

proc start_test {name date} {
  set dir [file dirname $::argv0]
  set output [file join $dir $name.test]
  set ::fd [open $output w]
puts $::fd [string trimleft "
# $date
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
# This file implements regression tests for SQLite library.
#

####################################################
# DO NOT EDIT! THIS FILE IS AUTOMATICALLY GENERATED!
####################################################
"]
  puts $::fd {set testdir [file dirname $argv0]}
  puts $::fd {source $testdir/tester.tcl}
  puts $::fd "set testprefix $name"
  puts $::fd ""
}

proc -- {args} {
  puts $::fd "# $args"
}

proc ========== {args} {
  puts $::fd "#[string repeat = 74]"
  puts $::fd ""
}

proc finish_test {} {
  puts $::fd finish_test
  close $::fd
}
