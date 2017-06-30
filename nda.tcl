package require base64
proc ndaenc {n} {
	return [string map {/ [} [::base64::encode [string tolower $n]]]
}

proc ndadec {n} {
	return [::base64::decode [string map {[ /} $n]]
}

array set nd {}
array set tnd {}

namespace eval nda {
	proc ::nda::get {path} {
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set pathe [lrange $parr 1 end]
		if {[info exists nd([lindex $parr 0])] && ![catch {dict get $nd([lindex $parr 0]) {*}$pathe} eee]} {return $eee}
	}
	proc ::nda::set {path val} {
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set pathe [lrange $parr 1 end]
		return [dict set nd([lindex $parr 0]) {*}$pathe $val]
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
		::set pathe [lrange $parr 1 end]
		if {[info exists tnd([lindex $parr 0])] && ![catch {dict get $tnd([lindex $parr 0]) {*}$pathe} eee]} {return $eee}
	}
	proc ::tnda::set {path val} {
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set pathe [lrange $parr 1 end]
		return [dict set tnd([lindex $parr 0]) {*}$pathe $val]
	}

	namespace export *
	namespace ensemble create
}
