package fr.gouv.stopc.robertserver.database.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import fr.gouv.stopc.robertserver.database.model.Registration;

@Repository
public interface RegistrationRepository extends MongoRepository<Registration, byte[]> {

    /**
     * Retrieve the number of users already notified and at risk again
     *
     * @return the count result
     */
    @Query(value = "{ atRisk: {$eq: true} , isNotified: {$eq: true}}", count = true)
    Long countNbUsersAtRiskAgain();

    /**
     * Retrieve the number of users at risk but not yet notified
     *
     * @return the count result
     */
    @Query(value = "{ atRisk: {$eq: true} , isNotified: {$eq: false}}", count = true)
    Long countNbUsersAtRiskAndNotNotified();

    /**
     * Retrieve the number of users at risk and notified
     *
     * @return the count result
     */
    @Query(value = "{ atRisk: {$eq: false} , isNotified: {$eq: true}}", count = true)
    Long countNbUsersNotified();

    /**
     * Retrieve the number of users not at risk but exposed to a user declared
     * positive
     *
     * @return the count result
     */
    @Query(value = "{ atRisk: {$eq: false}, isNotified: {$eq: false} , exposedEpochs: {$exists:true, $ne: []}}", count = true)
    Long countNbExposedUsersButNotAtRisk();

	/**
	 * Retrieve the number of users than epoch exposition with an epochId <= the epochId in parameter.
	 *
	 * @param minEpochId
	 * @return the count result
	 */
	@Query(value = "{exposedEpochs:{$elemMatch:{epochId:{$lte: ?0}}}}", count = true)
	Long countNbUsersWithOldEpochExpositions(int minEpochId);
}
