#!/bin/sh
exec scala -savecompiled "$0" "$@"
!#

import scala.io._
import java.io._

object Util {

  def require0(cond: Boolean, msg: String) = cond == false && sys.exit { println(msg); 1 }

  def toStr(xs: Array[String]) = xs.mkString("", "\t", "\n")

  def writer(fname: String)  = new PrintWriter(new File(fname))
}


object Trim {

  type sArray = Array[String]

  val rndBase    = Map("A" -> "C", "C" -> "T", "T" -> "G", "G" -> "A")
  val isDeletion = Set('*', '.')
  val validBases = Set('A', 'C', 'T', 'G') ++ isDeletion

  def apply(line: String): (sArray, sArray) = {
    if (line.startsWith("#")) (Array(line), Array[String]())
    else {
      val xs = line.split("\t", 6)
      val chr = xs(0)
      val pos = xs(1)
      val ref = xs(3)
      val alt = xs(4)

      Util.require0( alt.count(_ == ',') == 0, s"multiallelic sites not supported ($chr:$pos)" )

      Util.require0( (ref + alt).forall(validBases(_)) , s"unrecognized variant pattern at $chr:$pos ($ref, $alt)" )   

      if (isDeletion(ref.head) || isDeletion(alt.head)) {
        xs(3) = "A"
        xs(4) = "C"
        (xs, Array(chr, pos, ref, alt))
      }
      else {
        (ref.length, alt.length) match {
          case (0, _) | (_, 0) => sys.exit { println(s"unrecognized variant pattern at $pos ($ref, $alt)") ; 1 }
          case (1, 1) =>  (xs, Array[String]())
          case (1, _) =>  val newBase = rndBase(ref)
                          xs(4) = newBase
                          (xs, Array(chr, pos, ref, alt))
          case (_, 1) =>  val newBase = rndBase(alt)
                          xs(3) = newBase
                          (xs, Array(chr, pos, ref, alt))
          case _      =>  xs(3) = "A"
                          xs(4) = "C"
                          (xs, Array(chr, pos, ref, alt))
   
        }
      }
    }
  }
}

val in = args.lift(0).getOrElse( sys.exit { println("usage: indelTrimming vcfFile"); 1 } )

val Array(tableFw, rebasedFw) = Array(s"$in.hash", s"$in.trimmed.vcf").map(Util.writer)

for (line <- Source.fromFile(in).getLines) {
  val (rebased, tableItem) = Trim(line) 
  if (rebased.nonEmpty) rebasedFw.write(Util.toStr(rebased))
  if (tableItem.nonEmpty) tableFw.write(Util.toStr(tableItem))
}

List(tableFw, rebasedFw).foreach( _.close() )