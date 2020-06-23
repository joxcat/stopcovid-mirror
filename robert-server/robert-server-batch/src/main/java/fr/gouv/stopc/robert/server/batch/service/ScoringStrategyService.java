package fr.gouv.stopc.robert.server.batch.service;

import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robertserver.database.model.Contact;

import java.util.List;

public interface ScoringStrategyService {
    /**
     * Compute a risk score based on the nature of the contact
     *
     * @param contact
     */
    ScoringResult execute(Contact contact) throws RobertScoringException;

    int getScoringStrategyVersion();

    double aggregate(List<Double> scores);

    int getNbEpochsScoredAtRiskThreshold();
}
