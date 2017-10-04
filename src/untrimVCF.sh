#!/bin/sh
exec scala -savecompiled "$0" "$@"
!#

import scala.io._
import java.io._

case class Table(tableFile: String) {
  val table: Map[(String,String), Option[(String,String)]] = {
    Source.fromFile(tableFile).getLines.map {line =>
      val Array(chr, pos, ref, alt) = line.split("\t")
      ( (chr, pos), Some( (ref, alt) ) )
    }.toMap
  }

  def apply(chr: String, pos: String) = table.getOrElse( (chr,pos), None ) 
}

  
if (args.size < 1) 
  sys.exit{println("usage: cat trimmedVcfFile | indelsRestore hashtableFile > outputFile"); 1}

def toStr(xs: Array[String]) = xs.mkString("\t")  

val table = Table(args(0))

for (line <- Source.stdin.getLines) { 
  if (line.startsWith("#")) println(line)
  else {
    val xs = line.split("\t", 6)
    val chr = xs(0)
    val pos = xs(1)
    val decoded = 
      table(chr, pos) match {
        case Some((ref2, alt2)) => xs(3) = ref2
                                   xs(4) = alt2
                                   xs.mkString("\t")
        case None               => xs.mkString("\t")
      }

    println(decoded)
  }
}

