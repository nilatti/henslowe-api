import PropTypes from 'prop-types';
import {
  Col,
  Row,
  Tab,
  Tabs,
} from 'react-bootstrap'
import React, {
  Component
} from 'react'

class JobShow extends Component {
  constructor(props, context) {
    super(props, context);
    this.handleSelect = this.handleSelect.bind(this);

    this.state = {
      key: ''
    };
  }

  handleDeleteClick = () => {
    this.props.onDeleteClick(this.props.id)
  }

  handleSelect(key) {
    this.setState({
      key
    });
  }

  render() {
    return (
      <Col md={12}>
      <Row>
        <Col md={12} className="job-profile">
          <h2>{this.props.job.user.first_name} {this.props.job.user.last_name}</h2>
          <p><em>{this.props.job.specialization.title} for {this.props.job.production.play.title} at {this.props.job.theater.name}</em></p>
          <p>
            {this.props.job.start_date} - {this.props.job.end_date}
          </p>
          <span
            className='right floated edit icon'
            onClick={this.props.onEditClick}
          >
            <i className="fas fa-pencil-alt"></i>
          </span>
          <span
            className='right floated trash icon'
            onClick={this.handleDeleteClick}
          >
            <i className="fas fa-trash-alt"></i>
          </span>
        </Col>
      </Row>
      </Col>
    )
  }
}

JobShow.propTypes = {
  job: PropTypes.object.isRequired,
  onDeleteClick: PropTypes.func.isRequired,
  onEditClick: PropTypes.func.isRequired,
}

export default JobShow
