source nda.tcl
source 9999-protocol-common.tcl


namespace eval ts6 {
proc ::ts6::b64e {numb} {
        set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" {}]

        set res ""
	while {$numb != 0} {
		append res [lindex $b64 [expr {$numb % 36}]]
		set numb [expr {$numb / 36}]
	}
	if {[string length $res] == 0} {
		set res "A"
	}
        return [string reverse $res]
}

proc ::ts6::b64d {numb} {
        set b64 "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	set numb [string trimleft $numb "A"]
	set res 0
	for {set i 0} {$i<[string length $numb]} {incr i} {
		set new [string first [string index $numb $i] $b64]
		incr res [expr {$new * (36 * $i)+1}]
	}
        return $res
}
}

namespace eval ts6 {

proc ::ts6::sendUid {sck nick ident host dhost uid {realname "* Unknown *"} {modes "+oiS"} {server ""}} {
	if {""==$server} {set server $::sid($sck)}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $server]]}]]
	append sid [::ts6::b64e $server]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	if {![tnda get "ts6/$::netname($sck)/euid"]} {
		set sl [format ":%s UID %s 1 %s %s %s %s 0 %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $host $sid $sendnn $realname]
	} {
		set sl [format ":%s EUID %s 1 %s %s %s %s 0 %s%s %s * :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $dhost $sid $sendnn $host $realname]
	}
	tnda set "intclient/$::netname($sck)/${sid}${sendnn}" $uid
	tnda set "nick/$::netname($sck)/${sid}${sendnn}" $nick
	tnda set "ident/$::netname($sck)/${sid}${sendnn}" $ident
	tnda set "rhost/$::netname($sck)/${sid}${sendnn}" $host
	tnda set "vhost/$::netname($sck)/${sid}${sendnn}" $dhost
	tnda set "rname/$::netname($sck)/${sid}${sendnn}" $realname
	tnda set "ipaddr/$::netname($sck)/${sid}${sendnn}" 0
	puts $sck $sl
}

proc ::ts6::topic {sck uid targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s TOPIC %s :%s" $sid $sendnn $targ $topic]
}

proc ::ts6::setnick {sck uid newnick} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s NICK %s :%s" $sid $sendnn $newnick [clock format [clock seconds] -format %s]]
}

proc ::ts6::sethost {sck targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {![tnda get "ts6/$::netname($sck)/euid"]} {
		puts $sck [format ":%s ENCAP * CHGHOST %s %s" $sid $targ $topic]
	} {
		puts $sck [format ":%s CHGHOST %s %s" $sid $targ $topic]
	}
}

proc ::ts6::sendSid {sck sname sid {realname "In use by Services"}} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sl [format ":%s SID %s 1 %s :%s" [::ts6::b64e $sid] $sname [::ts6::b64e $sid] $realname]
	puts $sck $sl
}

proc ::ts6::privmsg {sck uid targ msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s PRIVMSG %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::metadata {sck targ direction type {msg ""}} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {[string toupper $direction] != "ADD" && [string toupper $direction] != "DELETE"} {putcmdlog "failed METADATA attempt (invalid arguments)";return} ;#no that didn't work
	if {[string toupper $direction] == "ADD"} {
		tnda set "metadata/$::netname($sck)/$targ/[ndaenc $type]" $msg
		puts $sck [format ":%s ENCAP * METADATA %s %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type] $msg]
	}
	if {[string toupper $direction] == "DELETE"} {
		tnda unset "metadata/$::netname($sck)/$targ/[ndaenc $type]"
		puts $sck [format ":%s ENCAP * METADATA %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type]]
	}
}

proc ::ts6::kick {sck uid targ tn msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s KICK %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc ::ts6::notice {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s NOTICE %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::part {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s PART %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::quit {sck uid msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s QUIT :%s" $sid $sendnn $msg]
	tnda unset "intclient/$::netname($sck)/${sid}${sendnn}"
	tnda unset "ident/$::netname($sck)/${sid}${sendnn}"
	tnda unset "rhost/$::netname($sck)/${sid}${sendnn}"
	tnda unset "vhost/$::netname($sck)/${sid}${sendnn}"
	tnda unset "rname/$::netname($sck)/${sid}${sendnn}"
	tnda unset "ipaddr/$::netname($sck)/${sid}${sendnn}"
	tnda unset "nick/$::netname($sck)/${sid}${sendnn}"
}

proc ::ts6::setacct {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	puts $sck [format ":%s ENCAP * SU %s %s" $sid $targ $msg]
	tnda set "login/$::netname($sck)/$targ" $msg
}

proc ::ts6::putmotd {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	puts $sck [format ":%s 372 %s :- %s" $sid $targ $msg]
}

proc ::ts6::putmotdend {sck targ} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	puts $sck [format ":%s 376 %s :End of global MOTD." $sid $targ]
}

proc ::ts6::putmode {sck uid targ mode parm {ts ""}} {
	if {$ts == ""} {
		if {[set ts [tnda get "channels/$::netname($sck)/[ndaenc [string tolower $targ]]/ts"]] == ""} {return} ;#cant do it, doesnt exist
	}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s TMODE %s %s %s %s" $sid $sendnn $ts $targ $mode $parm]
}

proc ::ts6::putjoin {sck uid targ {ts ""}} {
	if {$ts == ""} {
		if {[set ts [tnda get "channels/$::netname($sck)/[ndaenc [string tolower $targ]]/ts"]] == ""} {set ts [clock format [clock seconds] -format %s]}
	}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s SJOIN %s %s + :%s%s" $sid $ts $targ $sid $sendnn]
}

proc ::ts6::irc-main {sck} {
	global sid sock
	if {[eof $sck]} {close $sck}
	gets $sck line
	putloglev r * $line
	set line [string trim $line "\r\n"]
	set one [string match ":*" $line]
	set line [string trimleft $line ":"]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 0 [expr {$gotsplitwhere - 1}]] " "]}
	if {$gotsplitwhere==-1} {set payload [lindex $comd end]} {set payload [split [string range $line [expr {$gotsplitwhere + 2}] end] " "]}
	if {$gotsplitwhere != -1} {lappend comd $payload}
	if {[lindex $comd 0] == "PING"} {puts $sck "PONG $::servername :$payload"}
	if {[lindex $comd 0] == "SERVER"} {puts $sck "VERSION"}
	switch -nocase -- [lindex $comd $one] {
		"479" {putcmdlog $payload}

		"005" {
			foreach {tok} [lrange $comd 3 end] {
				foreach {key val} [split $tok "="] {
					if {$key == "PREFIX"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 1] {}]
						set modepref [split [lindex $mod 0] {}]
						foreach {c} $modechar {x} $modepref {
							tnda set "ts6/$::netname($sck)/prefix/$c" $x
						}
						foreach {x} $modechar {c} $modepref {
							tnda set "ts6/$::netname($sck)/pfxchar/$c" $x
						}
					} elseif {$key == "CHANMODES"} {
						set spt [split $val ","]
						tnda set "ts6/$::netname($sck)/chmparm" [format "%s%s" [lindex $spt 0] [lindex $spt 1]]
						tnda set "ts6/$::netname($sck)/chmpartparm" [lindex $spt 2]
						tnda set "ts6/$::netname($sck)/chmnoparm" [lindex $spt 3]
					}
				}
			}
		}

		"PRIVMSG" {
			if {[string index [lindex $comd 2] 0] == "#" || [string index [lindex $comd 2] 0] == "&" || [string index [lindex $comd 2] 0] == "!" || [string index [lindex $comd 2] 0] == "+" || [string index [lindex $comd 2] 0] == "."} {
				set client chan
				tds:callbind $sck pub "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				tds:callbind $sck evnt "-" "chanmsg" [lindex $comd 0] [lindex $comd 2] $payload
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				tds:callbind $sck msg $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				tds:callbind $sck "evnt" "-" "privmsg" [lindex $comd 0] [lindex $comd 2] $payload
			}
		}

		"NOTICE" {
			if {![tnda get "ts6/$::netname($sck)/connected"]} {return}
			if {[string index [lindex $comd 2] 0] == "#" || [string index [lindex $comd 2] 0] == "&" || [string index [lindex $comd 2] 0] == "!" || [string index [lindex $comd 2] 0] == "+" || [string index [lindex $comd 2] 0] == "."} {
				set client chan
				tds:callbind $sck pubnotc "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				tds:callbind $sck pubnotc-m "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				tds:callbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] $payload
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				tds:callbind $sck notc $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				tds:callbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] $payload
			}
		}

		"MODE" {
			if {[lindex $comd 3] == [tnda get "nick/$::netname($sck)/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 4] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/$::netname($sck)/[lindex $comd 0]" $state}
					}
				}
			}
		}

		"JOIN" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 3]]]]
			if {""==[tnda get "channels/$::netname($sck)/$chan/ts"]} {tds:callbind $sck create "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)}
			tds:callbind $sck join "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 1
		}

		"TMODE" {
			set ctr 4
			set state 1
			foreach {c} [split [lindex $comd 4] {}] {
				if {$c == "+"} {
					set state 1
				} elseif {$c == "-"} {
					set state 0
				} elseif {[string match [format "*%s*" $c] [tnda get "ts6/$::netname($sck)/chmparm"]] || ($state&&[string match [format "*%s*" $c] [tnda get "ts6/$::netname($sck)/chmpartparm"]])} {
					tds:callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] [lindex $comd [incr ctr]] $::netname($sck)
				} else {
					tds:callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] "" $::netname($sck)
				}
			}
		}

		"SJOIN" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 3]]]]
			if {[string index [lindex $comd 4] 0] == "+"} {
				set four 5
				if {[string match "*l*" [lindex $comd 4]]} {incr four}
				if {[string match "*f*" [lindex $comd 4]]} {incr four}
				if {[string match "*j*" [lindex $comd 4]]} {incr four}
				if {[string match "*k*" [lindex $comd 4]]} {incr four}
			} {
				set four 4
			}
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			foreach {nick} $payload {
				set un ""
				set uo ""
				set state uo
				foreach {c} [split $nick {}] {
					if {[string is integer $c]} {set state un}
					if {$state == "uo"} {set c [tnda get "ts6/$::netname($sck)/pfxchar/$c"] ; }
					if {"un"==$state} {append un $c}
					if {"uo"==$state} {append uo $c}
				}
				tds:callbind $sck join "-" "-" [lindex $comd 3] $un $::netname($sck)
				if {""!=$uo} {tnda set "channels/$::netname($sck)/$chan/modes/$un" $uo
					foreach {c} [split $uo {}] {
						tds:callbind $sck mode "-" + $c $un [lindex $comd 3] $un $::netname($sck)
					}
				}
			}

		}

		"PART" {
			tds:callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 0] $::netname($sck)
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
		}

		"KICK" {
			tds:callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 3] $::netname($sck)
		}

		"NICK" {
			tnda set "nick/$::netname($sck)/[lindex $comd 0]" [lindex $comd 2]
			tnda set "ts/$::netname($sck)/[lindex $comd 0]" [lindex $comd 3]
		}

		"EUID" {
			set num 9
			set ctr 1
			set oper 0
			set loggedin [lindex $comd 11]
			set realhost [lindex $comd 10]
			set modes [lindex $comd 4]
			if {[string match "*o*" $modes]} {set oper 1}
			if {"*"!=$loggedin} {
				tnda set "login/$::netname($sck)/[lindex $comd $num]" $loggedin
			}
			if {"*"!=$realhost} {
				tnda set "rhost/$::netname($sck)/[lindex $comd $num]" $realhost
			} {
				tnda set "rhost/$::netname($sck)/[lindex $comd $num]" [lindex $comd 7]
			}
			tnda set "nick/$::netname($sck)/[lindex $comd $num]" [lindex $comd 2]
			tnda set "oper/$::netname($sck)/[lindex $comd $num]" $oper
			tnda set "ident/$::netname($sck)/[lindex $comd $num]" [lindex $comd 6]
			tnda set "vhost/$::netname($sck)/[lindex $comd $num]" [lindex $comd 7]
			tnda set "ipaddr/$::netname($sck)/[lindex $comd $num]" [lindex $comd 8]
			tnda set "ts/$::netname($sck)/[lindex $comd $num]" [lindex $comd 4]
			tnda set "rname/$::netname($sck)/[lindex $comd $num]" $payload
			putloglev j * [format "New user at %s %s %s!%s@%s (IP address %s, vhost %s) :%s" $::netname($sck) [lindex $comd $num] [lindex $comd 2] [lindex $comd 6] [tnda get "rhost/$::netname($sck)/[lindex $comd $num]"] [lindex $comd 8] [tnda get "vhost/$::netname($sck)/[lindex $comd $num]"] $payload]
			tds:callbind $sck conn "-" "-" [lindex $comd $num]
		}

		"KLINE" {putloglev k * [format "KLINE: %s" $line]}
		"BAN" {putloglev k * [format "BAN: %s" $line]}

		"ENCAP" {
			switch -nocase -- [lindex $comd 3] {
				"SASL" {
					#don't bother
				}
				"KLINE" {
					putloglev k * [format "KLINE: %s" $line]
				}
				"SU" {
					if {$payload == ""} {set payload [lindex $comd 5]}
					tnda set "login/$::netname($sck)/[lindex $comd 4]" $payload
					if {$payload == ""} {tds:callbind $sck logout "-" "-" [lindex $comd 4]} {tds:callbind $sck login "-" "-" [lindex $comd 4] $payload}
				}
				"CERTFP" {
					tnda set "certfps/$::netname($sck)/[lindex $comd 0]" $payload
					tds:callbind $sck encap "-" "certfp" [lindex $comd 0] $payload
				}
				"METADATA" {
					switch -nocase -- [lindex $comd 4] {
						"ADD" {
							tnda set "metadata/$::netname($sck)/[lindex $comd 5]/[ndaenc [lindex $comd 6]]" $payload
							tds:callbind $sck encap "-" "metadata.[string tolower [lindex $comd 6]]" [lindex $comd 5] $payload
						}
						"DELETE" {
							tnda unset "metadata/$::netname($sck)/[lindex $comd 5]/[ndaenc $payload]"
							tds:callbind $sck encap "-" "metadata.[string tolower $payload]" [lindex $comd 5] ""
						}
					}
				}
			}
		}

		"TOPIC" {
			tds:callbind $sck topic "-" "-" [lindex $comd 2] [join $payload " "]
		}
		"QUIT" {
			if {![string is digit [string index [lindex $comd 0] 0]]} {
				set ocomd [lrange $comd 1 end]
				set on [lindex $comd 0]
				set comd [list [::ts6::nick2uid $::netname($sck) $on] {*}$ocomd]
				putcmdlog [format "Uh-oh, netsplit! %s -> %s has split" $on [::ts6::nick2uid $::netname($sck) $on]]
			}
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 0]"] {
				tds:callbind $sck part "-" "-" [ndadec $chan] [lindex $comd 0] $::netname($sck)
				tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
			}

			tnda unset "login/$::netname($sck)/[lindex $comd 0]"
			tnda unset "nick/$::netname($sck)/[lindex $comd 0]"
			tnda set "oper/$::netname($sck)/[lindex $comd 0]" 0
			tnda unset "ident/$::netname($sck)/[lindex $comd 0]"
			tnda unset "rhost/$::netname($sck)/[lindex $comd 0]"
			tnda unset "vhost/$::netname($sck)/[lindex $comd 0]"
			tnda unset "rname/$::netname($sck)/[lindex $comd 0]"
			tnda unset "ipaddr/$::netname($sck)/[lindex $comd 0]"
			tnda set "metadata/$::netname($sck)/[lindex $comd 0]" [list]
			tnda unset "certfps/$::netname($sck)/[lindex $comd 0]"
			tds:callbind $sck quit "-" "-" [lindex $comd 0] $::netname($sck)
		}

		"KILL" {
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 2]"] {
				tds:callbind $sck part "-" "-" [ndadec $chan] [lindex $comd 2]
				tnda set "userchan/$::netname($sck)/[lindex $comd 2]/$chan" 0
			}
			tnda unset "login/$::netname($sck)/[lindex $comd 2]"
			tnda unset "nick/$::netname($sck)/[lindex $comd 2]"
			tnda set "oper/$::netname($sck)/[lindex $comd 2]" 0
			tnda unset "ident/$::netname($sck)/[lindex $comd 2]"
			tnda unset "ipaddr/$::netname($sck)/[lindex $comd 2]"
			tnda unset "rhost/$::netname($sck)/[lindex $comd 2]"
			tnda unset "vhost/$::netname($sck)/[lindex $comd 2]"
			tnda unset "rname/$::netname($sck)/[lindex $comd 2]"
			tnda set "metadata/$::netname($sck)/[lindex $comd 2]" [list]
			tnda unset "certfps/$::netname($sck)/[lindex $comd 2]"
			tds:callbind $sck quit "-" "-" [lindex $comd 2] $::netname($sck)
		}

		"ERROR" {
			putcmdlog "Recv'd an ERROR $payload from $::netname($sck)"
		}

		"WHOIS" {
			# Usually but not always for a local client.
			set num [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
			append num [::ts6::b64e $::sid($sck)]
			set targ [::ts6::nick2uid $::netname($sck) $payload]
			if {[tnda get "nick/$::netname($sck)/$targ"] == ""} {
				puts $sck [format ":%s 401 %s %s :No such user." $num [lindex $comd 0] $payload]
			} else {
				puts $sck [format ":%s 311 %s %s %s %s * :%s" $num [lindex $comd 0] [tnda get "nick/$::netname($sck)/$targ"] [tnda get "ident/$::netname($sck)/$targ"] [tnda get "vhost/$::netname($sck)/$targ"] [tnda get "rname/$::netname($sck)/$targ"]]
			}
			puts $sck [format ":%s 318 %s %s :End of /WHOIS list." $num [lindex $comd 0] $payload]
		}

		"CAPAB" {
			tnda set "ts6/$::netname($sck)/euid" 0
			foreach {cw} [split $payload " "] {
				if {$cw == "EUID"} {tnda set "ts6/$::netname($sck)/euid" 1}
			}
			tnda set "ts6/$::netname($sck)/connected" 1
		}

		"PING" {
			set num [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
			append num [::ts6::b64e $::sid($sck)]
			if {[lindex $comd 3]==""} {set pong [lindex $comd 0]} {set pong [lindex $comd 3]}
			puts $sck [format ":%s PONG %s %s" $num $pong [lindex $comd 2]]
		}
	}
}

proc ::ts6::login {sck {osid "42"} {password "link"} {servname "net"}} {
	set num [string repeat "0" [expr {3-[string length [::ts6::b64e $osid]]}]]
	append num [::ts6::b64e $osid]
	global netname sid sock nettype
	set netname($sck) $servname
	set nettype($servname) ts6
	set sock($servname) $sck
	set sid($sck) $osid
	set sid($servname) $osid
	tnda set "ts6/$::netname($sck)/connected" 0
	tnda set "ts6/$::netname($sck)/euid" 0
	if {![info exists ::ts6(halfops)]} {tnda set "pfx/halfop" v} {tnda set "pfx/halfop" $::ts6(halfops)}
	if {![info exists ::ts6(ownermode)]} {tnda set "pfx/owner" o} {tnda set "pfx/owner" $::ts6(ownermode)}
	if {![info exists ::ts6(protectmode)]} {tnda set "pfx/protect" o} {tnda set "pfx/protect" $::ts6(protectmode)}
	if {![info exists ::ts6(euid)]} {set ::ts6(euid) 1}
	puts $sck "PASS $password TS 6 :$num"
	puts $sck "CAPAB :UNKLN BAN KLN RSFNC EUID ENCAP IE EX CLUSTER EOPMOD SVS SERVICES"
	puts $sck "SERVER $::servername 1 :chary.tcl for Eggdrop and related bots"
	puts $sck "SVINFO 6 6 0 :[clock format [clock seconds] -format %s]"
	puts $sck ":$num VERSION"
	tds:bind $sck mode - + ::ts6::checkop
	tds:bind $sck mode - - ::ts6::checkdeop

	chan event $sck readable [list ::ts6::irc-main $sck]
}

#source services.conf

proc ::ts6::nick2uid {netname nick} {
	foreach {u n} [tnda get "nick/$netname"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
}
proc ::ts6::intclient2uid {netname nick} {
	foreach {u n} [tnda get "intclient/$netname"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
}
proc ::ts6::uid2nick {netname u} {
	return [tnda get "nick/$netname/$u"]
}
proc ::ts6::uid2rhost {netname u} {
	return [tnda get "rhost/$netname/$u"]
}
proc ::ts6::uid2host {netname u} {
	return [tnda get "host/$netname/$u"]
}
proc ::ts6::uid2ident {netname u} {
	return [tnda get "ident/$netname/$u"]
}
proc ::ts6::nick2host {netname nick} {
	return [tnda get "host/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2ident {netname nick} {
	return [tnda get "ident/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2rhost {netname nick} {
	return [tnda get "rhost/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2ipaddr {netname nick} {
	return [tnda get "ipaddr/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::getts {netname chan} {
	return [tnda get "channels/$netname/[ndaenc $chan]/ts"]
}
proc ::ts6::getpfx {netname chan nick} {
	return [tnda get "channels/$netname/[ndaenc $chan]/modes/[::ts6::nick2uid $netname $nick]"]
}
proc ::ts6::getupfx {netname chan u} {
	return [tnda get "channels/$netname/[ndaenc $chan]/modes/$u"]
}
proc ::ts6::getpfxchars {netname modes} {
	set o ""
	foreach {c} [split $modes {}] {
		append o [nda get "ts6/$netname/prefix/$c"]
	}
	return $o
}
proc ::ts6::getmetadata {netname nick metadatum} {
	return [tnda get "metadata/$netname/[::ts6::nick2uid $netname $nick]/[ndaenc $metadatum]"]
}
proc ::ts6::getcertfp {netname nick} {
	return [tnda get "certfps/$netname/[::ts6::nick2uid $netname $nick]"]
}

proc ::ts6::checkop {mc s c p n} {
	set f $s
	set t $c
	if {[tnda get "ts6/$n/pfxchar/$mc"]==""} {return}
putcmdlog "up $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" [format {%s%s} [string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]] $mc]
}

proc ::ts6::checkdeop {mc s c p n} {
	set f $s
	set t $c
	if {[tnda get "ts6/$n/pfxchar/$mc"]==""} {return}
putcmdlog "down $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" [string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]]
}

proc ::ts6::getfreeuid {net} {
set work 1
set cns [list]
foreach {_ cnum} [tnda get "intclient/$net"] {lappend cns $cnum}
while {0!=$work} {set num [expr {[rand 300000]+10000}];if {[lsearch -exact $cns $num]==-1} {set work 0}}
return $num
}

namespace export *
namespace ensemble create
}

#ts6 login $::sock
