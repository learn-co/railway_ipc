Mox.defmock(RailwayIpc.StreamMock, for: RailwayIpc.StreamBehaviour)

Mox.defmock(RailwayIpc.PersistenceMock,
  for: RailwayIpc.PersistenceBehaviour
)

Mox.defmock(RailwayIpc.MessagePublishingMock,
  for: RailwayIpc.MessagePublishingBehaviour
)

Mox.defmock(RailwayIpc.MessageConsumptionMock,
  for: RailwayIpc.MessageConsumptionBehaviour
)
