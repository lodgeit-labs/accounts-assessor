
/* 
basically i'm flipping the kr paradigm upside-down, for the purpose of just frictionlessly encoding arbitrary information for future use, a NL verbalization is actually the most precise form, since it implicitly carries all the ambiguity and imprecision without trying to fight it
*/


'is a namespace'(xbrl)
'has description'(xbrl, "our internal ontology leveraging the xbrl formalism, + extensions, but without an actual formal mapping to any xbrl standard yet")


is_subclass_of(account,xbrl:fact)
'is a class'(
	xbrl:fact
)
'has property'(
	xbrl:fact, 
	xbrl:'fact has entity'
)
is_a_class(
	xbrl:entity
)
has_property(
	xbrl:entity, xbrl:'is head entity'
)


has_resource(lodgeit, 'clients api')
has_url('clients api', "http://sync-public-assets.s3-website-ap-southeast-2.amazonaws.com/#/Contact/get_contact")


is_a_class(clients:client)
has_property(clients:client, clients:type1)
has_range(clients:type1, [natural, unnatural, human, 'limited company', trust, partnership])
has_property(clients:client, clients:naturalness)
has_range(clients:naturalness, [natural, unnatural])


is_a_class(entity)
has_property(entity, 'entity type')
has_property('entity type', 'equity structure')

is_subclass_of(trust, entity)

is_subclass_of('trust equity structure', 'equity structure')

eq('trust equity structure'..equity, 'trust equity structure'..'settled sum')




prolog:
occurs(usually, eq('trust equity structure'..'settled sum', value('AUD', 10)))

quads:
g1 frequency usually.
graph g1:
	'trust equity structure' 'settled sum' S
	S eq [
		unit 'AUD'
		amount 10]
	




idk("The beneficiaries of the trust are represent via loans to beneficiaries, in the liability section of a balance sheet. Since the trust is indebted to the beneficiaries for all benefits and no loss. i.e. a trust does not share losses with beneficiaries.")












% mappings, alignment, ..



xbrl:fact  



