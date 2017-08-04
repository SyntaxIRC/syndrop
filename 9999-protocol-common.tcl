proc tds:bind {sock type client comd script} {
	set moretodo 1
	while {0!=$moretodo} {
		set bindnum [rand 1 10000000]
		if {[tnda get "binds/$sock/$type/$client/$comd/$bindnum"]!=""} {} {set moretodo 0}
	}
	tnda set "binds/$sock/$type/$client/$comd/$bindnum" $script
	return $bindnum
}

proc tds:unbind {sock type client comd id} {
	tnda unset "binds/$sock/$type/$client/$comd/$id"
}
proc tds:callbind {sock type client comd args} {
	puts stdout [tnda get "binds/mode"]
	if {""!=[tnda get "binds/$sock/$type/$client/$comd"]} {
		foreach {id script} [tnda get "binds/$sock/$type/$client/$comd"] {
			if {$script != ""} {
				set construct [list $script]
				foreach arg $args {lappend construct $arg}
				eval $construct
			}
		};return
	}
	#if {""!=[tnda get "binds/$type/-/$comd"]} {foreach {id script} [tnda get "binds/$type/-/$comd"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}
