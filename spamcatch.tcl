tds:bind $::ts6sock conn - - checkonion
package require json
package require ip
source onioncatch.tcl
set ouronion ""
set ourports [list 6697 5000 6665 6666 6667 6668 6669]

proc klineonion {uid ip ports} {
	set server $::sid($::ts6sock)
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $server]]}]]
	append sid [::ts6::b64e $server]
        set sendid [::ts6::b64e 44]
        set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
        append sendnn $sendid

	if {[string index $ip 0] == "\["} {set ip [string range $ip 1 end-1]}
	if {[string index $ip 0] == ":"} {set ip [format "0%s" $ip]}
	putloglev k * [format "Spamcatch: klining %s\[%s@%s %s\] for Tor" [::ts6::uid2nick $::netname($::ts6sock) $uid] [::ts6::uid2ident $::netname($::ts6sock) $uid] $ip $uid]
	puts $::ts6sock [format ":%s%s ENCAP * KLINE %s * %s :Using a Tor exit to access this IRC network is forbidden - subject to case-by-case restrictions, try %s on port 6667 or 6697." $sid $sendnn 86400 $ip $::ouronion]
	foreach {chan _} [tnda get "userchan/$::netname($::ts6sock)/$uid"] {
		tds:callbind $::ts6sock part "-" "-" [ndadec $chan] $uid
		tnda set "userchan/$::netname($::ts6sock)/$uid/$chan" 0
	}
	tnda set "login/$::netname($::ts6sock)/$uid" ""
	tnda set "nick/$::netname($::ts6sock)/$uid" ""
	tnda set "oper/$::netname($::ts6sock)/$uid" 0
	tnda set "ident/$::netname($::ts6sock)/$uid" ""
	tnda set "ipaddr/$::netname($::ts6sock)/$uid" ""
	tnda set "rhost/$::netname($::ts6sock)/$uid" ""
	tnda set "vhost/$::netname($::ts6sock)/$uid" ""
	tnda set "rname/$::netname($::ts6sock)/$uid" ""
	tnda set "metadata/$::netname($::ts6sock)/$uid" [list]
	tnda set "certfps/$::netname($::ts6sock)/$uid" ""
	tds:callbind $::ts6sock quit "-" "-" $uid $::netname($::ts6sock)
}

proc checkonion {uid} {
	set ipa [tnda get "ipaddr/$::netname($::ts6sock)/$uid"]
	if {$ipa=="0"} {return}
	if {[::ip::version $ipa] == 4} {
		set ip [::ip::contract $ipa]
	} elseif {[::ip::version $ipa] == 6} {
		set ip [format "\[%s\]" [::ip::contract $ipa]]
	} else {return}
	#::ts6::notice $::ts6sock 44 $uid [format "This IRC network uses Spamcatch technology to detect and destroy problematic users. Your IP, %s, is now being checked for a certain kind of open proxy that often falls through DNSBLs and BOPM." $ip]
	#::ts6::notice $::ts6sock 44 $uid "If you have no ill will, you need not fear. Thank you."
	putloglev jk * [format "Spamcatch: scanning %s\[%s@%s %s\] for Tor" [::ts6::uid2nick $::netname($::ts6sock) $uid] [::ts6::uid2ident $::netname($::ts6sock) $uid] $ip $uid]
	dlonion $ip $::ourports [list klineonion $uid $ip]
}

::ts6::sendUid $::ts6sock SpamCatch spamcatch unclespam. unclespam. 44 "I get rid of spammers."
