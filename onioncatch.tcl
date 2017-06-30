package require json

proc dlonion {host ports {cb {}}} {
	set jdf [open [format "|wget -qO- https://onionoo.torproject.org/details?search=%s" $host] r]
	set portlist $ports
	fileevent $jdf readable [list readit $host $jdf $portlist $cb]
}

proc readit {host jdf portlist cb} {
	set jda [read $jdf]
	close $jdf
	processit $jda $portlist $cb
}

proc processit {jda portlist cb} {
	set jdt [::json::json2dict $jda]

	set relays [dict get $jdt relays]
	set exitableportsonlist [list]

	foreach relay $relays {
		set portexitanyhost [list]
		foreach exitable [dict get $relay exit_policy] {
			set exitlist [split $exitable " "]
			foreach {type target} $exitlist {
				set tarp [split [string reverse $target] {}]
				set rport ""
				set rhost ""
				set seencolon 0
				set seendash 0
				foreach char $tarp {
					if {$char == ":"} {set seencolon 1; continue}
					if {$seencolon} {append rhost $char} {if {[string is digit $char] || $char == "-"} {append rport $char}}
					if {!$seencolon && $char == "-"} {set seendash 1; continue}
				}
				set host [string reverse $rhost]
				set port [string reverse $rport]
				set all 0
				if {$port == ""} {set port "1-65536"; set seendash 1; set all 1}
				if {$seendash} {
					# It's a range
					set portr [split $port "-"]
					set beginport [lindex $portr 0]
					set endport [lindex $portr 1]
					set lastport $beginport
					set ports [list]
					while {$lastport <= $endport} {
						lappend ports $lastport
						set lastport [expr {$lastport + 1}]
					}
					if {[llength $ports] == 0} {
						#puts stdout "Error: port list length 0 - Onionoo bug? Report it."
						continue
					}
					set strports [join $ports " "]
					set s s
				} else {
					set s ""
					set strports $port
				}
				if {[string tolower $type]=="accept"} {
					if {$seendash} {
						if {$host == "*"} {
							foreach po $ports {
								lappend portexitanyhost $po
							}
						}
					} else { ;#$seendash
						if {$host == "*"} {lappend portexitanyhost $port}
					}
				}
				if {$all} {set strports "all"}
			}
		}
		if {[llength $portlist] > 1} {
			foreach port $portlist {
				if {[lsearch -exact $portexitanyhost $port] && [dict get $relay running]} {
					lappend exitableportsonlist $port
				}
			}
		}
	}
	if {$cb != "" && [llength $exitableportsonlist] > 0} {
		lappend cb $exitableportsonlist
		eval $cb
	}
}
