# This whole didgeridoo is legacy code and I need to kill it with fire!

package require base64
proc ndaenc {n} {
	return [string map {/ [} [::base64::encode [string tolower $n]]]
}

proc ndadec {n} {
	return [::base64::decode [string map {[ /} $n]]
}

dict set nd {}
dict set tnd {}

namespace eval nda {
	proc ::nda::get {path} {
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set pathe [lrange $parr 1 end]
		if {[info exists nd] && ![catch {dict get $nd {*}$parr} eee]} {return $eee} {return ""}
	}

	proc ::nda::set {path val} {
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		return [dict set nd {*}$parr $val]
	}

	proc ::nda::unset {path} {
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		return [dict unset nd {*}$parr]
	}

	namespace export *
	namespace ensemble create
}

namespace eval tnda {
	proc ::tnda::get {path} {
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		#::set pathe [lrange $parr 1 end]
		if {[info exists tnd] && ![catch {dict get $tnd {*}$parr} eee]} {return $eee} {return ""}
	}
	proc ::tnda::set {path val} {
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		#::set pathe [lrange $parr 1 end]
		return [dict set tnd {*}$parr $val]
	}

	proc ::tnda::unset {path} {
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		return [dict unset tnd {*}$parr]
	}


	namespace export *
	namespace ensemble create
}
