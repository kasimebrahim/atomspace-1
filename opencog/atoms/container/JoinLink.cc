/*
 * JoinLink.cc
 *
 * Copyright (C) 2020 Linas Vepstas
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3 as
 * published by the Free Software Foundation and including the
 * exceptions at http://opencog.org/wiki/Licenses
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this program; if not, write to:
 * Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <opencog/atoms/atom_types/NameServer.h>

#include "JoinLink.h"

using namespace opencog;

void JoinLink::init(void)
{
	Type t = get_type();
	if (not nameserver().isA(t, JOIN_LINK))
	{
		const std::string& tname = nameserver().getTypeName(t);
		throw InvalidParamException(TRACE_INFO,
			"Expecting a JoinLink, got %s", tname.c_str());
	}
}

JoinLink::JoinLink(const HandleSeq&& hseq, Type t)
	: PrenexLink(std::move(hseq), t)
{
	init();
}

/* ================================================================= */

HandleSet JoinLink::min_container(void)
{
	Handle starter;

	// If there's only one variable, things should be easy...
	if (_variables.varseq.size() == 1)
	{
		Handle var(_variables.varseq[0]);

		if (_variables._simple_typemap.size() != 0)
			throw RuntimeException(TRACE_INFO, "Not supported yet!");

		// Get the type.
		HandleSet dtset = _variables._deep_typemap.at(var);
		if (dtset.size() != 1)
			throw RuntimeException(TRACE_INFO, "Not supported yet!");

		Handle dt = *dtset.begin();
		Type dtype = dt->get_type();

		if (SIGNATURE_LINK != dtype)
			throw RuntimeException(TRACE_INFO, "Not supported yet!");

		starter = dt->getOutgoingAtom(0);
	}

	if (_variables.varseq.size() != 1)
		throw RuntimeException(TRACE_INFO, "Not supported yet!");

	HandleSet containers;
	containers.insert(starter);

	return containers;
}

/* ================================================================= */

HandleSet JoinLink::max_container(void)
{
	HandleSet hs = min_container();
	HandleSet containers;
	for (const Handle& h: hs)
	{
		containers.insert(h);
	}
	return containers;
}

/* ================================================================= */

QueueValuePtr JoinLink::do_execute(AtomSpace* as, bool silent)
{
	// if (nullptr == as) as = _atom_space;
	QueueValuePtr qvp(createQueueValue());

printf("duude vardecls=%s\n", _vardecl->to_string().c_str());
printf("duude body=%s\n", _body->to_string().c_str());
printf("duude vars=%s\n", oc_to_string(_variables).c_str());

	HandleSet hs = max_container();

	// XXX FIXME this is really dumb, using a queue and then
	// copying things into it. Whatever. Fix this.
	for (const Handle& h : hs)
	{
		qvp->push(h);
	}

	qvp->close();
	return qvp;
}

ValuePtr JoinLink::execute(AtomSpace* as, bool silent)
{
	return do_execute(as, silent);
}

DEFINE_LINK_FACTORY(JoinLink, JOIN_LINK)

/* ===================== END OF FILE ===================== */
